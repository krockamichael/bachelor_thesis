--[[
	:module:: handler.lua
   	:platform: Linux
   	:synopsis: An interface to implement. Each function is to be run by Kong at the desired moment in the lifecycle of a request.
   	:copyright: (c) 2018 ArecaBay, Inc. All rights reserved. (This is modified based on tcp-log plugin provided by Kong)
	:moduleauthor:  Sekhar <contact@arecabay.com> (Nov 19, 2018)
]]
local BasePlugin = require "kong.plugins.base_plugin"
local basic_serializer = require "kong.plugins.ab-microsensor.abserialize" 
local cjson = require "cjson"
local utils = require "kong.tools.utils"

require("socket")

ssl = require("ssl")
https = require('ssl.https')

local resty_sha256 = require("resty.sha256")
local str = require("resty.string")

local AbSnifferHandler = BasePlugin:extend()

AbSnifferHandler.PRIORITY = 2
AbSnifferHandler.VERSION = "0.1.0"

globalinstance_id = nil
globaljwt = nil

--
-- Function get_body_data() takes max_body_size as argument and returns request body data upto max_body_size 
--
local function get_body_data(max_body_size)
  local req  = ngx.req

  req.read_body()
  local data  = req.get_body_data()
  if data then
    return string.sub(data, 0, max_body_size)
  end

  return ""
end

--
-- Function getinstance_id() returns the UUID that identifies each kong node uniquely
--
local function getinstance_id()

  local creds, err = kong.dao.abinstanceidstore:find_all({instance_id = "instance_id"})  
  if type(creds) == "table" then
    for k, v in pairs(creds) do
      if type(v) == "table" then
        for m, n in pairs(v) do
          if m == "key" then
		globalinstance_id = n
          end
        end
      end
    end
  end 
  if globalinstance_id == nil then
       local globalinstance_id = utils.uuid()
       local creds, err = kong.dao.abinstanceidstore:insert {
    		instance_id = "instance_id", key = globalinstance_id
 	}
       ngx.log(ngx.NOTICE, "\r\nInstanceID: ", globalinstance_id or "None\r\n")
  else
       ngx.log(ngx.NOTICE, "\r\nUUID: ", globalinstance_id or "None", "\r\n")
  end
end

--
-- Function getjwt() computes the hash required and gets the JWT token from localbay if it is not already present in datastore
--

local function getjwt(premature, conf)
  local dplet_id = conf.ab_microsensor_id
  local host = conf.ab_localbay_ip
  local port = conf.ab_localbay_port
  local timeout = conf.timeout
  local keepalive = conf.keepalive
  local pp = conf.ab_localbay_passphrase
  local tenant_id = conf.ab_tenant_id

  https.TIMEOUT= 1000000
  local jwt 
  local creds, err = kong.dao.abjwtstore:find_all({id = "jwt_token"})  

  if type(creds) == "table" then
    for k, v in pairs(creds) do
      if type(v) == "table" then
        for m, n in pairs(v) do
          if m == "key" then
		jwt = n
                ngx.log(ngx.NOTICE, "\r\nFound JWT: ", jwt or "None", err or "None", "\r\n") 
          end
        end
      end
    end
  end 


  if jwt == nil then
    local link = "http://" .. host .. ":" .. port .. "/api/v1/get/token?" .. "dplet_id=" .. dplet_id .. "&tenantid=" .. tenant_id
    local resp = {}
    local body, code, headers, statusline = https.request(link)
    --[[
        {
                                url = link,
                                headers = { ['Connection'] = 'close' }        
                                --sink = ltn12.sink.table(resp)
                                 }
      ]]
   
  if code~=200 then 
	ngx.log(ngx.ERR, "Status Code is: ", code) 
    return 
  end
  local uuids = cjson.decode(body)

  local x = pp .. "_" .. uuids["uuid1"]
  local sha256 = resty_sha256:new()
  sha256:update(x)
  local x_digest = sha256:final()
  local y = str.to_hex(x_digest)

  local z = y .. "_" .. uuids["uuid2"]
  sha256 = resty_sha256:new()
  sha256:update(z)
  local z_digest = sha256:final()
  local final_pp = str.to_hex(z_digest)

  if globalinstance_id == nil then 
     getinstance_id()
  else 
    ngx.log(ngx.NOTICE, "\r\nInstanceId Present: ", globalinstance_id, "\r\n")
  end

  link = "http://" .. host .. ":" .. port .. "/api/v1/get/token?h=" .. final_pp .. "&dplet_id=" .. dplet_id .. "&instance_id=" .. globalinstance_id .. "&tenantid=" .. tenant_id
  body, code, headers, statusline = https.request(link)

  jwt = cjson.decode(body)

  local creds, err = kong.dao.abjwtstore:insert {
    id = "jwt_token", key = jwt["jwt"]
  }

-- Check for statur and return if error comes
    ngx.log(ngx.NOTICE, "\r\nAB JWT Store Saved: ", jwt["jwt"], "--", err, "\r\n")
    return jwt["jwt"]
  else
    ngx.log(ngx.NOTICE, "\r\nLocalBay Extracted: ", jwt, "\r\n")
    if globalinstance_id == nil then
       getinstance_id()
    else
       ngx.log(ngx.NOTICE, "\r\nInstanceId Present: ", globalinstance_id, "\r\n")
    end
    return jwt
  end
end

--
-- Function log() sends the captured event in serialized format to localbay with jwt as auth token 
--
local function log(premature, conf, jwt, message)
  if premature then
    return
  end

  local ok, err
  local dplet_id = conf.ab_microsensor_id
  local host = conf.ab_localbay_ip
  local port = conf.ab_localbay_port
  local timeout = conf.timeout
  local keepalive = conf.keepalive
  local pp = conf.ab_localbay_passphrase
  local auth_token = jwt

  ngx.log(ngx.NOTICE, "\r\nLocalBay JWT available to log function: ", auth_token, "\r\n")
  local body = cjson.encode(message)
  local message2 = "POST /api/v1/data?dplet_id=" .. dplet_id .. " HTTP/1.1\r\nHost: " .. host .. "\r\nAuthorization: Bearer " .. auth_token .. "\r\nConnection: Keep-Alive\r\nContent-Type: application/json\r\nContent-Length: " .. string.len(body) .. "\r\n\r\n" .. body
  
-- TLS/SSL client parameters (omitted)
  local params = {
    mode = "client",
    protocol = "tlsv1",
    verify = "none",
    options = "all",
  }
  local line

  local conn = socket.tcp()
  conn:settimeout(conf.timeout)
  conn:connect(host, port)

  -- TLS/SSL initialization
  local ssl_init = ssl.wrap(conn, params)
  ssl_init:dohandshake()

  ssl_init:send(message2 .. "\r\n")
  line, err = ssl_init:receive()
  ngx.log(ngx.NOTICE, "\r\nResponse from Receiver in log function: ",line or "None", "--", err or "None", "\r\n")
  conn:close()
end

--
-- This function is plugin handler's constructor. Since this module is extending the Base Plugin handler, it's only role is to instantiate itself with a name. 
-- The name is plugin name "ab-microsensor" as it will be printed in the logs.
--

function AbSnifferHandler:new()
  AbSnifferHandler.super.new(self, "ab-microsensor")
end

--
-- This function is executed upon every Nginx worker process’s startup. An instance_id for each kong node is generated in UUID format and stored in DB
--

function AbSnifferHandler:init_worker()
  AbSnifferHandler.super.init_worker(self)
    
  getinstance_id()
end

--
-- This function is executed for every request from a client and before it is being proxied to the upstream service.
-- Gets the request body if available and calls JWT computing function
--

function AbSnifferHandler:access(conf)
  AbSnifferHandler.super.access(self)

  if conf.log_body and conf.max_body_size > 0 then
    ngx.ctx.request_body = get_body_data(conf.max_body_size)
    ngx.ctx.response_body = ""
  end
  
  local new, premature
  new = getjwt(premature, conf)
  globaljwt = new
end

--
-- This function is executed for each chunk of the response body received from the upstream service.
-- Gets the repsonse body 
--

function AbSnifferHandler:body_filter(conf)
  AbSnifferHandler.super.body_filter(self)

  if conf.log_body and conf.max_body_size > 0 then
    local chunk = ngx.arg[1]
    local res_body = ngx.ctx.response_body .. (chunk or "")
    ngx.ctx.response_body = string.sub(res_body, 0, conf.max_body_size)
  end
end

--
-- This function is executed in the log phase of nginx context that is when the last response byte has been sent to the client.
-- Calls the serialize function to prepare the JSON structure and calls the log function which sends event to localbay
--

function AbSnifferHandler:log(conf)
  AbSnifferHandler.super.log(self)

  local message = basic_serializer.serialize(ngx, instance_id)
  local new, premature
  new = globaljwt

  local ok, err = ngx.timer.at(0, log, conf, new, message)
end
return AbSnifferHandler

