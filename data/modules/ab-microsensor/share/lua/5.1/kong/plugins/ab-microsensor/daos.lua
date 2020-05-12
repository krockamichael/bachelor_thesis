--[[
  : Custom DAOs schema for tables abjwtstore and abinstanceidstore
]]

local utils = require "kong.tools.utils"

local JWT_SCHEMA = {
  primary_key = {"id"},
  table = "abjwtstore",
  fields = {
    id = {type = "string", default = "jwt_token"},
    key = {type = "string", required = false, unique = true, default = utils.random_string}
  },
}

local INSTANCE_SCHEMA = 
 {
  primary_key = {"instance_id"},
  table = "abinstanceidstore",
  fields = {
    instance_id = {type = "string", default = "instance_id"},
    key = {type = "string", required = false, unique = true, default = utils.random_string}
  },
}

return {abjwtstore = JWT_SCHEMA, abinstanceidstore = INSTANCE_SCHEMA}
