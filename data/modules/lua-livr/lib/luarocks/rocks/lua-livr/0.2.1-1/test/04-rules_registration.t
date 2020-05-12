#!/usr/bin/env lua

require 'Test.More'

plan(7)

local livr = require 'LIVR.Validator'

livr.register_default_rules{
    strong_password = function ()
        return function (value)
            if value ~= nil and value ~= '' then
                if type(value) == 'number' then
                    value = tostring(value)
                end
                if type(value) ~= 'string' then
                    return value, 'FORMAT_ERROR'
                end
                if #value < 6 then
                    return value, 'WEAK_PASSWORD'
                end
            end
            return value
        end
    end
}

local validator = livr.new{
    code            = 'alphanumeric',
    password        = 'strong_password',
    address         = { nested_object  = {
        street      = 'alphanumeric',
        password    = 'strong_password'
    } }
}
ok( validator )

validator:register_rules{
    alphanumeric = function ()
        return function (value)
            if value ~= nil and value ~= '' then
                if type(value) == 'number' then
                    value = tostring(value)
                end
                if type(value) ~= 'string' then
                    return value, 'FORMAT_ERROR'
                end
                if not value:match'^[a-z0-9]+$' then
                    return value, 'NOT_ALPHANUMERIC'
                end
            end
            return value
        end
    end
}

type_ok( livr.default_rules.strong_password, 'function', "Default rules should contain 'strong_password' rule" )
nok( livr.default_rules.alphanumeric, "Default rules should not contain 'alphanumeric' rule" )

type_ok( validator:get_rules().strong_password, 'function', "Validator rules should contain 'strong_password' rule" )
type_ok( validator:get_rules().alphanumeric, 'function', "Validator rules should contain 'alphanumeric' rule" )

local data, err = validator:validate{
    code            = '!qwe',
    password        = 123,
    address         = {
        street      = 'Some Street!',
        password    = 'qwer'
    }
}
nok( data, "should return false due to validation errors" )
is_deeply( err, {
    code            = 'NOT_ALPHANUMERIC',
    password        = 'WEAK_PASSWORD',
    address         = {
        street      = 'NOT_ALPHANUMERIC',
        password    = 'WEAK_PASSWORD'
    }
}, "should contain error codes" )

