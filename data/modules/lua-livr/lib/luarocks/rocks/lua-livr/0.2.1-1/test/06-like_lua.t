#!/usr/bin/env lua

require 'Test.More'

plan(5)

local livr = require 'LIVR.Validator'
type_ok( livr.default_rules.like_lua, 'function' )
livr.default_rules.like = livr.default_rules.like_lua

local validator = livr.new{
    first_name  = { like = "^%a+$" },
    last_name   = { like = "^%w+$" },
    age         = { like = "^[1-9][0-9]*$" },
}
ok( validator )

local data, err = validator:validate{
    first_name  = 'Fran3ois',
    last_name   = 'Perrad ',
    age         = { 51 },
}
nok( data )
is_deeply( err, {
    first_name  = 'WRONG_FORMAT',
    last_name   = 'WRONG_FORMAT',
    age         = 'FORMAT_ERROR',
} )

data = validator:validate{
    first_name  = 'Francois',
    last_name   = 'Perrad',
    age         = 51,
}
ok( data )

