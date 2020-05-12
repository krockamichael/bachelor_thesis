local class = require 'stuart.class'

-- log4j, roughly
local FATAL = 50000
local ERROR = 40000
local WARN = 30000
local INFO = 20000
local DEBUG = 10000
local TRACE = 0

local levelName = {
  [FATAL] = 'FATAL',
  [ERROR] = 'ERROR',
  [WARN] = 'WARN',
  [INFO] = 'INFO',
  [DEBUG] = 'DEBUG',
  [TRACE] = 'TRACE'
}

local Logger = class.new()

Logger.FATAL = FATAL
Logger.ERROR = ERROR
Logger.WARN = WARN
Logger.INFO = INFO
Logger.DEBUG = DEBUG
Logger.TRACE = TRACE

function Logger:_init()
  self.level = INFO
end

function Logger:debug(msg)
  if self.level <= DEBUG then
    self:log{level=DEBUG, message=msg}
  end
end

function Logger:error(msg)
  if self.level <= ERROR then
    self:log{level=ERROR, message=msg}
  end
end

function Logger:info(msg)
  if self.level <= INFO then
    self:log{level=INFO, message=msg}
  end
end

function Logger:log(event)
  local s = {levelName[event.level], event.message}
  if io ~= nil then
    io.stderr:write(table.concat(s,' ') .. '\n')
  else
    print(table.concat(s,' ') .. '\n')
  end
end

function Logger:setLevel(level)
  self.level = level
end

function Logger:trace(msg)
  if self.level <= TRACE then
    self:log{level=TRACE, message=msg}
  end
end

function Logger:warn(msg)
  if self.level <= WARN then
    self:log{level=WARN, message=msg}
  end
end

return Logger
