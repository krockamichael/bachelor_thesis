local BasePlugin = require "kong.plugins.base_plugin"
local geodb = require "mmdb"

local IpLocationHandler = BasePlugin:extend()

function IpLocationHandler:new()
    IpLocationHandler.super.new(self, "ip-location")
end

function IpLocationHandler:access(conf)
    IpLocationHandler.super.access(self)
    local status, cityDb = pcall(geodb.open, "GeoLite2-" .. (conf.cityLevel and "City" or "Country") .. ".mmdb")
    if status == false then
        return
    end
    local result = cityDb:search_ipv4("92.44.47.88")

    if type(result) ~= "table" then
        return
    end
    if result.continent then
        ngx.header["X-Ip-Continent"] = result.continent.code
    end
    if result.country then
        ngx.header["X-Ip-Country"] = result.country.iso_code
    end
    if result.city then
        ngx.header["X-Ip-City"] = result.city.names.en
    end
    if result.location then
        ngx.header["X-Ip-LatLon"] = result.location.latitude .. ";" .. result.location.latitude
    end
end

return IpLocationHandler