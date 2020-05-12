local BasePlugin = require "kong.plugins.base_plugin"
local req_set_header = ngx.req.set_header

local HelloHandler = BasePlugin:extend()

HelloHandler.PRIORITY = 2000
HelloHandler.VERSION = 0.1.0

function HelloHandler:new()
  HelloHandler.super.new(self, "kong-oas")
end

function Handler:header_filter(conf)
  HelloHandler.super.header_filter(self)

  local greeting = "Hello, " .. conf.name .. "."

  kong.response.set_header('X-Hello-Header', greeting)
end

return HelloHandler