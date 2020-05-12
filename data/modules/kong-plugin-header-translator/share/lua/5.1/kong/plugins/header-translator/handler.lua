local BasePlugin = require "kong.plugins.base_plugin"
local singletons = require "kong.singletons"
local normalizer = require "kong.plugins.header-translator.normalizer"
local Logger = require "logger"

local HeaderTranslatorHandler = BasePlugin:extend()

HeaderTranslatorHandler.PRIORITY = 900

local function load_translation(input_header_name, input_header_value, output_header_name)
    return kong.dao.header_translator_dictionary:find({
        input_header_name = input_header_name,
        input_header_value = input_header_value,
        output_header_name = output_header_name
    })
end

function HeaderTranslatorHandler:new()
    HeaderTranslatorHandler.super.new(self, "header-translator")
end

function HeaderTranslatorHandler:access(conf)
    HeaderTranslatorHandler.super.access(self)

    local headers = kong.request.get_headers()

    if not headers[conf['input_header_name']] then return end

    local input_header_name = normalizer(conf['input_header_name'])
    local input_header_value = headers[conf['input_header_name']]
    local output_header_name = normalizer(conf['output_header_name'])

    local cache_key = singletons.dao.header_translator_dictionary:cache_key(input_header_name, input_header_value, output_header_name)
    local translation, err = singletons.cache:get(cache_key, nil, load_translation, input_header_name, input_header_value, output_header_name)

    if err then
        Logger.getInstance(ngx):logError(err)
    end

    if translation then
        kong.service.request.set_header(conf['output_header_name'], translation.output_header_value)
    end
end

return HeaderTranslatorHandler
