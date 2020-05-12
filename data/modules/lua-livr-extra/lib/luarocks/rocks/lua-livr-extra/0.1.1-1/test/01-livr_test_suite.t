#!/usr/bin/env lua

require 'Test.More'

if not pcall(require, 'lfs') then
    skip_all 'no lfs'
end
if not pcall(require, 'dkjson') then
    skip_all 'no json'
end

plan'no_plan'

require'LIVR.Rules.Extra'
local livr = require'LIVR.Validator'
local lfs = require'lfs'
local decode = require'dkjson'.decode
local encode = require'dkjson'.encode

local function iterate_test_data (dir_basename, fn)
    local dir_fullname = '../test/' .. dir_basename
    local tests = {}
    for fname in lfs.dir(dir_fullname) do
        if fname:match'^[^.]' then
            tests[#tests+1] = fname
        end
    end
    table.sort(tests)
    for i = 1, #tests do
        local test_name = tests[i]
        local test_dir = dir_fullname .. '/' .. test_name
        local data = { test_name = test_name }
        for fname in lfs.dir(test_dir) do
            if fname:match'%.json$' then
                local f = assert(io.open(test_dir .. '/' .. fname))
                local json = f:read '*a'
                f:close()
                local content = assert(decode(json))
                local key = fname:gsub('%.json', '')
                data[key] = content
            end
        end
        subtest(dir_basename .. '/' .. test_name, function ()
            fn(data)
        end)
    end
end

iterate_test_data('test_suite/positive', function (data)
    local validator = livr.new(data.rules)
    local output, err = validator:validate(data.input)
    nok( err, "should return no errors" )
    if err then
        diag(encode(err))
    end
    is_deeply( output, data.output, "should return validated data" )
end)

iterate_test_data('test_suite/negative', function (data)
    local validator = livr.new(data.rules)
    local output, err = validator:validate(data.input)
    nok( output, "should return false" )
    is_deeply( err, data.errors, "should contain valid errors" )
end)

done_testing()

