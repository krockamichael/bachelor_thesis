#!/usr/bin/env lua

require 'Test.More'

plan(4)

local livr = require 'LIVR.Validator'

local validator = livr.new({
    code            = 'required',
    password        = { 'required', { min_length = 3 } },
    address         = { nested_object  = {
        street  = { min_length = 5 },
    } }
}, true)
ok( validator )

local data, err = validator:validate{
    code        = '  ',
    password    = ' 12  ',
    address     = {
        street  = '  hell '
    }
}
nok( data, "return false due to validation errors for trimmed values" )
is_deeply( err, {
    code        = 'REQUIRED',
    password    = 'TOO_SHORT',
    address     = {
        street  = 'TOO_SHORT',
    }
}, "should contain error codes" )

data = validator:validate{
    code        = ' A ',
    password    = ' 123  ',
    address     = {
        street  = '  hello '
    }
}
is_deeply( data, {
    code        = 'A',
    password    = '123',
    address     = {
        street  = 'hello',
    }
}, "should contain trimmed data" )

