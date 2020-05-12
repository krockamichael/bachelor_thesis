---------------------------------------------------------------------------------------------------------
-- Distributed task helper for Tundrawolf
-- Author: aimingoo@wandoujia.com
-- Copyright (c) 2015.09
--
-- Note:
--	*) a interface of task define helper.
--	*) encode/decode fields for local supported object, from/to JSON compatible field types.
---------------------------------------------------------------------------------------------------------

local BASE64_encode = ngx.encode_base64
local BASE64_decode = ngx.decode_base64

local JSON = require('cjson')
local JSON_decode = JSON.decode
local JSON_encode = JSON.encode

-- encode to json compatible object
local function encode_task_fields(obj)
	local taskDef, jsonTypes = {}, {['string']=true, ['boolean']=true, ['number']=true, ['table']=true}
	for key, result in pairs(obj) do
		if type(key) ~= 'string' then
			print('Unsupported key type in taskObjet, key type: ' .. type(key))
		else
			local t = type(result)
			if t == 'table' then
				taskDef[key] = encode_task_fields(result)
			elseif t == 'function' then
				local str = string.dump(result)
				taskDef[key] = 'script:lua:base64:' .. BASE64_encode(str)
			elseif jsonTypes[t] then
				taskDef[key] = result
			else
				print('Unsupported data type in taskObjet, key: ' .. key .. ', result type: ' .. t)
			end
		end
	end
	return taskDef
end

-- decode fields from object (the object from standard taskDef JSON text)
--	*) simple prefix check only, non standard
local function decode_task_fields(taskDef)
	for name, value in pairs(taskDef) do
		local t = type(value)
		if t == 'table' then
			decode_task_fields(taskDef[name])
		elseif ((t == 'string') and -- performance: try hard match for top prefix
				(string.match(value, '^data:') or string.match(value, '^script:'))) then
			if string.match(value, '^script:lua:base64:') then
				taskDef[name] = loadstring(BASE64_decode(string.sub(value, 19)))()
			elseif string.match(value, '^script:lua:utf8:') then
				-- TODO: utf8 support
				taskDef[name] = loadstring('return ' .. string.sub(value, 17))()
			else
				local matched, rules = false, {'^data:base64:', '^data:string:base64:'}
				for _, prefix in ipairs(rules) do
					if string.match(value, prefix) then matched = string.len(prefix); break end
				end
				if not matched then error('unknow data encode type') end
				taskDef[name] = BASE64_decode(string.sub(value, matched))
			end
		end
	end
	return taskDef
end

return {
	version = '1.1',

	-- DONT Modify These Constants !
	TASK_BLANK = "task:99914b932bd37a50b983c5e7c90ae93b",	-- {}
	TASK_SELF = "task:6934703c3b4d0714b25f4b5e6148c11a",		-- {"promised":"return self"}
	TASK_RESOURCE = "task:01d13608d51c57d757ce4c630952f49a",	-- {"promised":"return resource"}
	LOGGER = "!",

	encode = function(task)
		return JSON_encode(encode_task_fields(task))
	end,

	decode = function(taskDef)
		return decode_task_fields(JSON_decode(taskDef))
	end,

	run = function(_, task, args)
		return { run = task, arguments = args }
	end,

	map = function(_, distributionScope, task, args)
		return { map = task, scope = distributionScope, arguments = args}
	end,

	require = function(resId)
		return this.run(this.TASK_RESOURCE, resId)
	end,

	reduce = function(self, distributionScope, task, args, reduce)
		if not reduce then
			return self:run(args, self:map(distributionScope, task)) -- args as reduce
		else
			return self:run(reduce, self:map(distributionScope, task, args))
		end
	end,

	daemon = function(self, distributionScope, task, daemon, deamonArgs)
		return self:map(distributionScope, task, self:run(daemon, deamonArgs))
	end,
}