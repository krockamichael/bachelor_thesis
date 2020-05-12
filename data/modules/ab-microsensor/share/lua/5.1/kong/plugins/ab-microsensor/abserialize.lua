--[[
   :module:: abserialize.lua
   :platform: Linux
   :synopsis: This module serializes metadata from http transaction.
]]

local tablex = require "pl.tablex"

local _M = {}

local EMPTY = tablex.readonly({})

function _M.serialize(ngx, instance_id)
  local authenticated_entity
  if ngx.ctx.authenticated_credential ~= nil then
    authenticated_entity = {
      id = ngx.ctx.authenticated_credential.id,
      consumer_id = ngx.ctx.authenticated_credential.consumer_id
    }
  end
  --local node_id = assert(kong.node.get_id())
  return {
   data = {
   type = "kong",
   id = math.random(100000, 1000000),
   attributes = {
   event_metadata = {
      dpletId = 10,
      dpletType = 5,
      instance_id = instance_id
    },
    request = {
      request_uri = ngx.var.request_uri,
      upstream_uri = ngx.var.upstream_uri,
      request_url = ngx.var.scheme .. "://" .. ngx.var.host .. ":" .. ngx.var.server_port .. ngx.var.request_uri,
      querystring = ngx.req.get_uri_args(), -- parameters, as a table
      method = ngx.req.get_method(), -- http method
      headers = ngx.req.get_headers(),
      -- headers = ngx.req.raw_header(true),
      size = ngx.var.request_length,
      body = ngx.ctx.request_body
    },
    response = {
      status = ngx.status,
      headers = ngx.resp.get_headers(),
      size = ngx.var.bytes_sent,
      body = ngx.ctx.response_body
    },
    tries = (ngx.ctx.balancer_address or EMPTY).tries,
    latencies = {
      kong = (ngx.ctx.KONG_ACCESS_TIME or 0) +
             (ngx.ctx.KONG_RECEIVE_TIME or 0) +
             (ngx.ctx.KONG_REWRITE_TIME or 0) +
             (ngx.ctx.KONG_BALANCER_TIME or 0),
      proxy = ngx.ctx.KONG_WAITING_TIME or -1,
      request = ngx.var.request_time * 1000
    }, 
    authenticated_entity = authenticated_entity,
    api = ngx.ctx.api,
    consumer = ngx.ctx.authenticated_consumer,
    client_ip = ngx.var.remote_addr,
    started_at = ngx.req.start_time() * 1000
  }
}
}
end

return _M
