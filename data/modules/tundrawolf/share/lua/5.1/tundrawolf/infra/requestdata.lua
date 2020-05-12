---------------------------------------------------------------------------------------------------------
-- Distributed request arguments helper for Tundrawolf
-- Author: aimingoo@wandoujia.com
-- Copyright (c) 2015.11
--
-- parse request body_data and merge into search arguments object
---------------------------------------------------------------------------------------------------------

local JSON_decode = require('cjson').decode

-- mix/copy fields from ref to self
--	*) code from lib/Distributed.lua
local function mix(self, ref, expanded)
	if ref == nil then return self end

	if type(ref) == 'function' then return expanded and ref or nil end
	if type(ref) ~= 'table' then return ref end

	self = (type(self) == 'table') and self or {}
	for key, value in pairs(ref) do
		self[key] = mix(self[key], value, expanded)
	end
	return self
end

local decoder = {
	["application/json"] = function(dataString)
		local ok, result = pcall(JSON_decode, dataString)
		if ok then return result end
	end,

	["application/x-www-form-urlencoded"] = function(dataString)
		return ngx.decode_args(dataString)
	end
}

local defaultContentType = "application/x-www-form-urlencoded";
local tryDefaultDecoder = function(dataString)  -- try decode as urlencoded
	local maxNameLength = 25	-- argName max-length is 25-1
	for i = 1, math.min(dataString:len(), maxNameLength) do
		if dataString:byte(i) == 61 then -- char '='
			return decoder[defaultContentType](dataString)
		end
	end
end

local function parseRequestData()
	local uri_args = ngx.req.get_uri_args()
	if ngx.var.request_method == 'GET' then return uri_args end -- or ngx.var.args

	-- local contentType = ngx.header['content_type']  -- error, will access response header
	-- Context-Type in RFC, it's "a single type/subtype, followed by optional parameters", parameter schema: *( ";" parameter )
	--	*) @see http://greenbytes.de/tech/webdav/rfc2616.html#rfc.section.14.17
	--	*) @see http://greenbytes.de/tech/webdav/rfc2616.html#media.types
	local contentType, mixin = ngx.var.content_type, true
	local arr = split(contentType, '%s*;%s*')
	if #arr > 1 then
		contentType = table.remove(arr, 1)
		local parameter = ngx.decode_args(table.concat(arr, '&'))
		if parameter.mixin then
			mixin = tostring(parameter.mixin):lower() ~= 'false'	-- else 'true' or otherwise default
		end
	end

	local decode = not contentType and tryDefaultDecoder or decoder[string.lower(contentType)]
	if not decode then return uri_args end

	ngx.req.read_body()
	if not ngx.var.request_body then return uri_args end

	local args = decode(ngx.var.request_body)
	return mixin and mix(uri_args, args) or args
end

return {
	parse = parseRequestData
}