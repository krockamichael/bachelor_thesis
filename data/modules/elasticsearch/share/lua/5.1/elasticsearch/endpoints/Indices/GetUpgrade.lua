-------------------------------------------------------------------------------
-- Importing modules
-------------------------------------------------------------------------------
local IndicesEndpoint = require "elasticsearch.endpoints.Indices.IndicesEndpoint"

-------------------------------------------------------------------------------
-- Declaring module
-------------------------------------------------------------------------------
local GetUpgrade = IndicesEndpoint:new()

-------------------------------------------------------------------------------
-- Declaring Instance variables
-------------------------------------------------------------------------------

-- The parameters that are allowed to be used in params
GetUpgrade.allowedParams = {
  ["wait_for_completion"] = true,
  ["only_ancient_segments"] = true,
  ["ignore_unavailable"] = true,
  ["allow_no_indices"] = true,
  ["expand_wildcards"] = true,
  ["human"] = true
}

-------------------------------------------------------------------------------
-- Function to calculate the http request method
--
-- @return    string    The HTTP request method
-------------------------------------------------------------------------------
function GetUpgrade:getMethod()
  return "GET"
end

-------------------------------------------------------------------------------
-- Function to calculate the URI
--
-- @return    string    The URI
-------------------------------------------------------------------------------
function GetUpgrade:getUri()
  local uri = "/_upgrade"

  if self.index ~= nil then
    uri = "/" .. self.index .. uri
  end
  
  return uri
end

-------------------------------------------------------------------------------
-- Returns an instance of GetUpgrade class
-------------------------------------------------------------------------------
function GetUpgrade:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

return GetUpgrade
