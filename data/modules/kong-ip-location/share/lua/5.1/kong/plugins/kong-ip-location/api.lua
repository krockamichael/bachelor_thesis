local IO = require "kong.tools.io"

return {
    ["/geoip"] = {
        GET = function(self, dao_factory, helpers)
            local result = { country = false, city = false }

            for _, type in ipairs({ "Country", "City" }) do
                local n = os.tmpname()
                local r, statusCode = IO.os_execute("curl http://geolite.maxmind.com/download/geoip/database/GeoLite2-" .. type .. ".mmdb.gz > " .. n, true)

                if statusCode == 0 then
                    local r, statusCode = IO.os_execute("gzip -d " .. n, true)
                end
                if statusCode == 0 then
                    IO.os_execute("mv " .. n .. " GeoLite2-" .. type .. ".mmdb", true)
                    result[string.lower(type)] = true
                end
            end
            self:write({ { json = result }, format = "json", status = 200 })
        end
    }
}
