#!/usr/bin/env lua

---
-- Servicekit: a platform-agnostic daemonization API
--
-- These are the routines that the ServiceKit user calls directly.
--
-- @module servicekit
--
local _servicekit = {}


local _events = require "servicekit.events"
local posix = require 'posix'


---
-- Contains the version number of this ServiceKit instance
--
_servicekit.version = "1.0 2012.1109"

---
-- Contains the platform this ServiceKit instance runs on
--
_servicekit.platform = "posix"



--
-- Detach from our controlling terminal.
--
local function detach()

	--
	-- Fork. Parent dies. Negative pids equal an error.
	--
	local pid = posix.fork()
	if pid < 0 then 
		err, errno = posix.errno()
		error("Fork failed, errno " .. tostring(err))
	end
	
	-- We're the parent.
	if pid > 0 then 
		os.exit(0) 
	end


	--
	-- Become process group leader. This causes a full disconnect
	-- from the controlling terminal.
	--
	-- Minimal error handling. This failing is rare.
	--
	assert(posix.setpid('s'), 'Cannot start new session')


	--
	-- Set working directory to '/', so filesystem mounting/unmounting
	-- isn't a bear.
	--
	-- We will let people who want a chroot() do that later.
	--
	-- No error message? Sorry. We're detached now.
	--
	assert(posix.chdir('/'))
	
	
	--
	-- Disconnect stdin/out/err and replace with /dev/null. This
	-- prevents a stray print() command or io.read/write from molesting
	-- a hapless network socket.
	--
	local devnull, err = posix.open("/dev/null", posix.O_RDONLY)
	assert(devnull, "Couldn't open /dev/null: " .. tostring(err))
			
	assert(posix.dup2(devnull, 0), "Cannot dup stdin")
	assert(posix.dup2(devnull, 1), "Cannot dup stdout")
	assert(posix.dup2(devnull, 2), "Cannot dup stderr")

end


---
-- Handle a sigterm or sigint
--
local function term_handler()
	_events.beginstop()
end


---
-- Handle a sighup
--
local function reload_handler()
	_events.reload()
end



---
-- Setup signal handling.
--
local function setsignals()

	posix.signal(posix.SIGINT, term_handler)
	posix.signal(posix.SIGTERM, term_handler)
	posix.signal(posix.SIGHUP, reload_handler)

end




---
-- Setup a new service. MUST be called before anything else.
--
-- @param events A table of event handler callbacks that implement your
--					service. The minimal set of events consists of just
--					run() and beginstop().
--
-- @see events
--
function _servicekit.setup( events )

	assert(type(events) == 'table')
	
	for k, v in pairs(events) do
		assert(_events[k], 'Unknown event: ' .. k)
		_events[k] = v
	end

	_events.ready = true
end


---
-- Runs the service. 
--
-- @param detached If true, the program detaches into the background.
--					Set to false to keep the program in the foreground
--					instead. If omitted, defaults to true.
--
function _servicekit.run( detached )

	assert(_events.ready, "Service is undefined: call setup() first")
	
	if detached == nil then detached = true end
	if detached then detach() end
	
	setsignals()
	
	_events.start()
	_events.run()
	_events.stop()
	
end


---
-- Returns the process ID, or some other valid identifier on other
-- platforms.
--
function _servicekit.pid()

	return posix.getpid('pid')

end


return _servicekit
