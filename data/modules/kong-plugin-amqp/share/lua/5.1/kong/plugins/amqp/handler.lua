
-- Grab pluginname from module name
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

-- load the base plugin object and create a subclass
local plugin = require("kong.plugins.base_plugin"):extend()
local amqp = require "amqp"
local cjson = require("cjson")
local uuid = require("resty.uuid")
--local enclosure = require("kong.plugins.amqp.enclosure")

local constants = require("kong.constants")

local function has_amqp_module()
  for _, v in pairs(constants.PROTOCOLS) do
    if v == "amqp" then
      ngx.log(ngx.DEBUG, "Kong already contains AMQP protocol!")
      return true 
    end
  end
  return false
end

local function readAll(file)
  local f = assert(io.open(file, "rb"))
  local content = f:read("*all")
  f:close()
  return content
end

--
-- Include de amqp protocol to the constants protocol
-- 
local function include_amqp()
  module_path = package.searchpath('kong.constants', package.path)
  content = readAll(module_path)
  
  content = string.gsub(content, '(http = "http")', 'amqp = "http",\n  %1')
  local f = io.open(module_path, "w")
  f:write(content)
  f:close()
end


-- constructor
function plugin:new()
  plugin.super.new(self, plugin_name)

  ngx.log(ngx.DEBUG, has_amqp_module())
 
  if not has_amqp_module() then
    include_amqp()
  end
end


---[[ handles more initialization, but AFTER the worker process has been forked/created.
-- It runs in the 'init_worker_by_lua_block'
function plugin:init_worker()
  plugin.super.init_worker(self)
end --]]


---[[ runs in the 'access_by_lua_block'
function plugin:access(conf)
  plugin.super.access(self)

  
  local ctx = amqp_get_context(conf)
  amqp_connect(ctx)

  uid = uuid.generate()
  amqp_publish(ctx, kong.request.get_raw_body(), uid)

  response = get_response(uid)
  ngx.say(response)
  
  ctx:teardown()
  ctx:close()

  ngx.ctx.status = ngx.HTTP_CREATED
  ngx.exit(ngx.ctx.status)
end --]]


---[[ runs in the 'header_filter_by_lua_block'
function plugin:header_filter(plugin_conf)
  plugin.super.header_filter(self)

  ngx.header["Content-Type"] = "application/json"
  --ngx.status = ngx.ctx.status
end --]]



function amqp_get_context(conf)
  local ctx = amqp:new({
    role = 'producer',
    exchange = conf.exchange,
    routing_key = conf.routing_key,
    ssl = kong.router.get_service().protocol == "https",
    user = conf.user,
    password = conf.password,
    no_ack = false,
    durable = true,
    auto_delete = true,
    exclusive = false,
    properties = {}
  })

  ngx.log(ngx.DEBUG, "AMQP context created successfully")

  return ctx
end

function amqp_connect(ctx)

  ctx:connect(
    kong.router.get_service().host,
    kong.router.get_service().port
  )
  ctx:setup()

  ngx.log(
    ngx.DEBUG, 
    "AMQP connected successfully at: ",
    "amqp://",
    kong.router.get_service().host, ":",
    kong.router.get_service().port
  )

  return ctx
end

function amqp_publish(ctx, message, uid)
  local ok, err = ctx:publish(message, {}, {correlation_id = uid})
  
  if err then
    ngx.log(ngx.ERR, "Internal server errror: ", err)
    ngx.say(cjson.encode({error = "Internal Server Error"}))

    ngx.ctx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.exit(ngx.ctx.status)
  end

  ngx.log(ngx.DEBUG, "Raw Body Published successfully")
end

function get_response(id)
  resp = cjson.encode({
    uuid = id, 
    time = ngx.localtime()
  })

  ngx.log(ngx.DEBUG, "AMQP Response body generated with ID: ", id)
  
  return resp
end

-- set the plugin priority, which determines plugin execution order
plugin.PRIORITY = 1000

-- return our plugin object
return plugin
