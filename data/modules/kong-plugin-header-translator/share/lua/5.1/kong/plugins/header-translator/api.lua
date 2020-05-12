local crud = require "kong.api.crud_helpers"
local normalizer = require "kong.plugins.header-translator.normalizer"

local function should_be_updated(translation, params)
    return not (translation.input_header_name == params.input_header_name and
           translation.input_header_value == params.input_header_value and
           translation.output_header_name == params.output_header_name and
           translation.output_header_value == params.output_header_value)
end

return {
    ["/header-dictionary/:input_header_name/:input_header_value/translations/:output_header_name"] = {
        before = function(self)
            self.params.input_header_name = normalizer(self.params.input_header_name)
            self.params.output_header_name = normalizer(self.params.output_header_name)
        end,

        POST = function(self, dao_factory)
            crud.post(self.params, dao_factory.header_translator_dictionary)
        end,

        PUT = function(self, dao_factory, helpers)
            local translation, err = dao_factory.header_translator_dictionary:find({
                input_header_name = self.params.input_header_name,
                input_header_value = self.params.input_header_value,
                output_header_name = self.params.output_header_name
            })

            if err then
                helpers.responses.HTTP_INTERNAL_SERVER_ERROR("Failed to find translation.")
            end

            if not translation then
                crud.post(self.params, dao_factory.header_translator_dictionary)
            else
                if should_be_updated(translation, self.params) then
                    crud.put(self.params, dao_factory.header_translator_dictionary)
                else
                    helpers.responses.send_HTTP_OK(translation)
                end
            end
        end,

        GET = function(self, dao_factory, helpers)
            local translation, err = dao_factory.header_translator_dictionary:find({
                input_header_name = self.params.input_header_name,
                input_header_value = self.params.input_header_value,
                output_header_name = self.params.output_header_name
            })

            if err or not translation then
                helpers.responses.send_HTTP_NOT_FOUND('Resource does not exist')
            end

            helpers.responses.send_HTTP_OK(translation)
        end,

        DELETE = function(self, dao_factory)
            crud.delete(self.params, dao_factory.header_translator_dictionary)
        end,
    }
}
