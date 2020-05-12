
--
-- lua-LIVR-extra : <https://fperrad.frama.io/lua-LIVR-extra/>
--

local primitive_type = require'LIVR.helpers'.primitive_type
local rules = require'LIVR.Validator'.default_rules
local error = error
local next = next
local tonumber = tonumber
local tostring = tostring
local type = type
local _ENV = nil

rules.base64 = function (_, padding)
    local patt = '^[%w+/]+=*$'
    return function (value)
        if value ~= nil and value ~= '' then
            if not primitive_type[type(value)] then
                return value, 'FORMAT_ERROR'
            end
            if type(value) ~= 'string' or (padding ~= 'relaxed' and #value % 4 ~= 0) or not value:match(patt) then
                return value, 'MALFORMED_BASE64'
            end
        end
        return value
    end
end

local truth = {
    [0] = false,
    [1] = true,
    ['0'] = false,
    ['1'] = true,
    [false] = false,
    [true] = true,
}
rules.boolean = function ()
    return function (value)
        if value ~= nil and value ~= '' then
            if not primitive_type[type(value)] then
                return value, 'FORMAT_ERROR'
            end
            local bool = truth[value]
            if bool == nil then
                return value, 'NOT_BOOLEAN'
            end
            value = bool
        end
        return value
    end
end

rules.credit_card = function ()
    return function (value)
        if value ~= nil and value ~= '' then
            if not primitive_type[type(value)] then
                return value, 'FORMAT_ERROR'
            end
            if type(value) ~= 'string' or #value < 14 or #value > 16 or not value:match'^%d+$' then
                return value, 'WRONG_CREDIT_CARD_NUMBER'
            end
            local sum = 0
            local parity = 1
            for i = 1, #value do
                local n = tonumber(value:sub(i, i))
                n = n * (parity + 1)
                if n > 9 then
                    n = n - 9
                end
                sum = sum + n
                parity = 1 - parity
            end
            if sum % 10 ~= 0 then
                return value, 'WRONG_CREDIT_CARD_NUMBER'
            end
        end
        return value
    end
end

rules.ipv4 = function ()
    return function (value)
        if value ~= nil and value ~= '' then
            if not primitive_type[type(value)] then
                return value, 'FORMAT_ERROR'
            end
            if type(value) ~= 'string' then
                return value, 'NOT_IP'
            end
            local t = { value:match'^(%d+)%.(%d+)%.(%d+)%.(%d+)$' }
            if #t ~= 4 then
                return value, 'NOT_IP'
            end
            for i = 1, 4 do
                local n = t[i]
                if n:match'^0%d' or tonumber(n) > 255 then
                    return value, 'NOT_IP'
                end
            end
        end
        return value
    end
end

rules.is = function (_, allowed_value)
    return function (value)
        if value == nil or value == '' then
            return value, 'REQUIRED'
        end
        if not primitive_type[type(value)] then
            return value, 'FORMAT_ERROR'
        end
        if tostring(value) == tostring(allowed_value) then
            return allowed_value
        end
        return value, 'NOT_ALLOWED_VALUE'
    end
end

rules.list_length = function (_, min_length, max_length)
    min_length = tonumber(min_length)
    if not min_length then
        error"LIVR: undefined list_length"
    end
    max_length = tonumber(max_length) or min_length
    return function (value)
        if value ~= nil and value ~= '' then
            if type(value) ~= 'table' then
                return value, 'FORMAT_ERROR'
            end
            if #value < min_length then
                return value, 'TOO_FEW_ITEMS'
            end
            if #value > max_length then
                return value, 'TOO_MANY_ITEMS'
            end
        end
        return value
    end
end

rules.list_items_unique = function ()
    return function (value)
        if value ~= nil and value ~= '' then
            if type(value) ~= 'table' then
                return value, 'FORMAT_ERROR'
            end
            local seen = {}
            local success = true
            for i = 1, #value do
                local v = value[i]
                if not primitive_type[type(v)] then
                    return value, 'INCOMPARABLE_ITEMS'
                end
                if seen[v] then
                    success = false
                end
                seen[v] = true
            end
            if not success then
                return value, 'NOT_UNIQUE_ITEMS'
            end
        end
        return value
    end
end

rules.md5 = function ()
    return function (value)
        if value ~= nil and value ~= '' then
            if not primitive_type[type(value)] then
                return value, 'FORMAT_ERROR'
            end
            if type(value) ~= 'string' or #value ~= 32 or not value:match'^%x+$' then
                return value, 'NOT_MD5'
            end
        end
        return value
    end
end

rules.mongo_id = function ()
    return function (value)
        if value ~= nil and value ~= '' then
            if not primitive_type[type(value)] then
                return value, 'FORMAT_ERROR'
            end
            if type(value) ~= 'string' or #value ~= 24 or not value:match'^%x+$' then
                return value, 'NOT_ID'
            end
        end
        return value
    end
end

local function get_value (params, path)
    local i = 1
    for w, pos in path:gmatch'(%w+)/()' do
        i = pos
        params = params[tonumber(w) or w]
        if type(params) ~= 'table' then
            return nil
        end
    end
    return params[path:sub(i)]
end
rules.required_if = function (_, query)
    local k, v
    if query then
        if type(query) == 'table' then
            k, v = next(query)
        end
        if not primitive_type[type(v)] then
            error "LIVR: the target value of the 'require_if' rule is missed or incomparable"
        end
    end
    return function (value, params)
        if k and tostring(get_value(params, k)) == tostring(v) and (value == nil or value == '') then
            return value, 'REQUIRED'
        end
        return value
    end
end

local uuid_patt = {
    v1 = '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$',
    v2 = '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$',
    v3 = '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-3%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$',
    v4 = '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-4%x%x%x%-[89ABab]%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$',
    v5 = '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-5%x%x%x%-[89ABab]%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$',
}
rules.uuid = function (_, version)
    local patt = uuid_patt[version or 'v4']
    if not patt then
        error("LIVR: unsupported uuid version: " .. tostring(version))
    end
    return function (value)
        if value ~= nil and value ~= '' then
            if not primitive_type[type(value)] then
                return value, 'FORMAT_ERROR'
            end
            if type(value) ~= 'string' or #value ~= 36 or not value:match(patt) then
                return value, 'NOT_UUID'
            end
        end
        return value
    end
end

local m = {}
m._NAME = ...
m._VERSION = "0.1.1"
m._DESCRIPTION = "lua-LIVR-extra : more LIVR rules"
m._COPYRIGHT = "Copyright (c) 2018-2019 Francois Perrad"
return m
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
