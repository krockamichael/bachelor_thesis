-- will be gradually migrated to kong.db
local jwt = require "resty.jwt"
local singletons = require "kong.singletons"

-- load base plugin object and create a subclass
local BasePlugin = require("kong.plugins.base_plugin")
local VerifyTokenHandler = BasePlugin:extend()

local HTTP_RESPONSES = {
  UNAUTHORIZED = 401
}

VerifyTokenHandler.PRIORITY = 800

-- Retrieve the access token from header
local function parse_jwt (header)
  local auth_header_parts = {}
  local access_token

  -- Split the header by spaces so that Bearer TOKEN will become ["Bearer", TOKEN]
  for part in string.gmatch(header, "%S+") do
    table.insert(auth_header_parts, part)
  end

  -- retrieve the access token if the authorization contains a bearer token
  if #auth_header_parts == 2 and (auth_header_parts[1]:lower() == "bearer") then
    access_token = auth_header_parts[2]
  end

  return access_token
end

local function decode_jwt (access_token)
  local decoded_jwt = jwt:load_jwt(access_token)
  return decoded_jwt
end

-- verify jwt is not blacklisted
local function verify_jwt(access_token)

  -- get jti from token
  local decoded_jwt = decode_jwt(access_token)

  -- retrieve the session_id
  local jti = decoded_jwt.payload.jti

  -- check database to see if the token is blacklisted
  local blacklisted, err = kong.db.invalidated_tokens:select ({session_id = jti})

  -- if the token exists in the database, then it was previously blacklisted
  if blacklisted ~= nil then
    -- return 401
    return kong.response.exit(HTTP_RESPONSES.UNAUTHORIZED, {message="Unauthorized"})
  end
end

-- constructor
function VerifyTokenHandler:new()
  VerifyTokenHandler.super.new(self, "verify-token")
end

-- runs on every request
function VerifyTokenHandler:access(plugin_conf)
  VerifyTokenHandler.super.access(self)

  -- only verify if the authorization header exists
  local jwt = kong.request.get_header("authorization")
  if jwt ~= nil then
    local access_token = parse_jwt(jwt)

    -- if we cannot retrieve the access token then return 401
    if access_token == nil then
      return kong.response.exit(HTTP_RESPONSES.UNAUTHORIZED, {message="Unauthorized"})
    end
    verify_jwt(access_token)
  end
end

return VerifyTokenHandler

