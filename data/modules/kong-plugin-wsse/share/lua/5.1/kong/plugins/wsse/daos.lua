local utils = require "kong.tools.utils"

local SCHEMA = {
    primary_key = { "id" },
    table = "wsse_keys",
    cache_key = { "key" },
    fields = {
        id = { type = "id", dao_insert_value = true },
        consumer_id = { type = "id", required = true, foreign = "consumers:id" },
        key = { type = "string", unique = true, required = true },
        secret = { type = "string", default = utils.random_string },
        strict_timeframe_validation = { type = "boolean", default = true },
        key_lower = { type = "string", unique = true, required = true }
    }
}

return { wsse_keys = SCHEMA }