#!/usr/bin/env lua

require 'Test.More'

plan(2)

local livr = require 'LIVR.Validator'

livr.register_default_rules{
    my_ucfirst = function ()
        return function (value)
            if type(value) == 'number' then
                value = tostring(value)
            end
            if type(value) == 'string' then
                value = value:sub(1,1):upper() .. value:sub(2)
            end
            return value
        end
    end,
    my_lc = function ()
        return function (value)
            if type(value) == 'number' then
                value = tostring(value)
            end
            if type(value) == 'string' then
                value = value:lower()
            end
            return value
        end
    end,
    my_trim = function ()
        return function (value)
            if type(value) == 'number' then
                value = tostring(value)
            end
            if type(value) == 'string' then
                value = value:gsub('^%s+', '')
                value = value:gsub('%s+$', '')
            end
            return value
        end
    end,
}

local validator = livr.new{
    word1   = { 'my_trim', 'my_lc', 'my_ucfirst' },
    word2   = { 'my_trim', 'my_lc' },
    word3   = { 'my_ucfirst' },
}
ok( validator )

local data = validator:validate{
    word1   = ' wordOne ',
    word2   = ' wordTwo ',
    word3   = 'wordThree ',
}
is_deeply( data, {
    word1   = 'Wordone',
    word2   = 'wordtwo',
    word3   = 'WordThree ',
}, "should apply changes to values" )

