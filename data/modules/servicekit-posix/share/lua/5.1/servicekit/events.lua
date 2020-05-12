#!/usr/bin/env lua

---
-- Events are callbacks defined by the user of Servicekit. These
-- do the actual work of the service. All recieve no arguments and
-- are not expected to return values.
--
-- @module events
--
local _events = {}


---
-- Called once the service has detached and is ready to run.
-- Optional. If not present, it is silently ignored.
--
function _events.start()
	return true
end


---
-- Called to enter the service's main loop. Manditory. Service will
-- automatically shut down if not present.
--
function _events.run()
	return true
end


---
-- Called to gracefully reload configuration. Optional. If not
-- given, reload requests will be silently ignored.
--
-- On Posix systems, this is fired when the daemon recieves a SIGHUP.
--
function _events.reload()
	return true
end


---
-- Called BEFORE a service begins it's shutdown. Don't cleanup
-- here, just trigger the main loop to exit.
--
-- You MUST define this event, and it MUST not call os.exit(). 
-- Otherwise, ServiceKit will not know how to gracefully shutdown
-- your main event loop!
--
-- On Posix systems, this is fired when the daemon recieves SIGTERM
-- or SIGINT.
--
function _events.beginstop()
	return true
end


---
-- Called after the main loop has exited. Optional. If not
-- present, it is silently ignored.
--
function _events.stop()
	return true
end


return _events
