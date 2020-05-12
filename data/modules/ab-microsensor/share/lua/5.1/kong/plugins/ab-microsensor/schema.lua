--[[
   : Config Information`
]]
return {
  fields = {
    ab_microsensor_id = {required = true, type = "number"},
    ab_microsensor_name = {type = "string"},
    ab_localbay_ip = { required = true, type = "string" },
    ab_localbay_port = { required = true, type = "number" },
    timeout = { default = 6000000, type = "number" },
    keepalive = { default = 6000000, type = "number" },
    log_body = { default = true, type = "boolean" },
    max_body_size = { default = 1073741824, type = "number" },
    ab_localbay_passphrase = {required = true, type = "string"},
    ab_tenant_id = {required = true, type = "string"}
  }
}
