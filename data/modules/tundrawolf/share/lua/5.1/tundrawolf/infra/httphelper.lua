---------------------------------------------------------------------------------------------------------
-- Distributed http client helper for Tundrawolf
-- Author: aimingoo@wandoujia.com
-- Copyright (c) 2015.10
--
-- Note:
--	*) a interface of distributed http client requests
---------------------------------------------------------------------------------------------------------

local Promise = require('lib.Promise')
local JSON_encode = require('cjson').encode

-- local proxy_pass_interface = '/YOUR/INTERFACE/IN_NGINX_CONF' -- faked/custom ngx_cc interface
local proxy_pass_interface = '/_/cast'  -- ngx_cc interface
local querystring_stringify = ngx.encode_args
local querystring_parse = ngx.decode_args

----------------------------------------------------------------------------------------------------------------
-- Utils
----------------------------------------------------------------------------------------------------------------

-- check paraments separator for url
local function find_separator(url)
	return string.find(url, '?') and '&' or '?'
end

-- url transform for outsite proxy_pass, @see ngx_cc.remote()
--		from 'http://xxxx.xxx.xx.x/PATH/...'
--		to   '/_/cast/PATH/...'
local function ngxcc_transform2(url)
	local addr = string.match(url, '^[^/]*//[^/]+')
	if not addr then return end
	return proxy_pass_interface .. string.sub(url, string.len(addr)+1),
		string.match(addr, '^[^/]*//([^:]+):?(.*)')
end

local function ngxcc_transform(url, opt)
	local uri2, host, port = ngxcc_transform2(url)
	port = not port and "" or ((port=="" or port=="80") and "" or ":"..port)
	if uri2 then
		-- be compatible ngx_cc, serverAddr as cc_host and ignore cc_port
		return uri2, setmetatable({vars = { cc_host = host..port, cc_port = "" }}, {__index=opt})
	end
end

-- asQuery(obj)
local function asQuery(obj)
	return ((not (obj.method or obj.data)) and querystring_stringify(obj)  -- default is simple GET request
		or ((obj.method and (string.upper(obj.method) == 'GET')) and querystring_stringify(obj.vars or {}) -- force as GET request
		or obj))
end

-- asQueryString(obj)
local function asQueryString(args)
	return type(args) == 'string' and args or querystring_stringify(args)
end

-- asRequest(query), for ngx_cc only
local function asRequest(query)
	local t = type(query)
	if t == 'nil' or t == 'string' then
		return query
	elseif t == 'table' then
		local request_string, request_options = false, query
		if query.args then
			if not query.data then
				local headers = query.headers or {}
				if not query.headers then query.headers = headers end
				if not headers["Content-Type"] then -- reset to default
					headers["Content-Type"] = "application/x-www-form-urlencoded"
				end

				if string.lower(headers["Content-Type"]) == "application/json" then
					query.data = JSON_encode(type(query.args) == 'table' and query.args
						or querystring_parse(tostring(query.args)))
				else
					query.data = asQueryString(query.args)
				end
			else
				-- send original request, <params> append to url
				request_string = asQueryString(query.args)
			end
			query.args = ""
			query.method = "POST"
		end
		-- fix for nginx_lua, and return
		if type(request_options.method) == 'string' then
			request_options.method = ngx['HTTP_'..request_options.method]
		end
		request_options.body = query.data
		return request_string, request_options
	else
		error('unknow distributed request type')
	end
end

----------------------------------------------------------------------------------------------------------------
-- distributed_request
----------------------------------------------------------------------------------------------------------------

-- need promise three arguments as arrResult
local function distributed_request(arrResult)
	--  In older versions of Nginx, the limit was 50 concurrent subrequests and in more recent versions,
	--	Nginx 1.1.x onwards, this was increased to 200 concurrent subrequests. 
	local URLs, taskId, args = unpack(arrResult)
	local max_subrequests, results = 64, {}
	local query =  (type(args) == 'table') and asQuery(args) or (args ~= nil and tostring(args) or nil)
	local request_string, request_options = asRequest(query)
	for i = 1, #URLs, max_subrequests do
		local subrequests, left = {}, i-1
		for j = i, math.min(#URLs, left+max_subrequests), 1 do
			local url, opt = ngxcc_transform(URLs[j], request_options)
			if not url then return Promise.reject({index = j, reason = "URLs parse error"}) end -- fake reject

			if request_string then
				url = url .. taskId .. find_separator(url) .. request_string
			else
				url = url .. taskId
			end
			table.insert(subrequests, {url, opt})
		end
		for j, resp in ipairs({ngx.location.capture_multi(subrequests)}) do
			local status = tonumber(resp.status) or 200
			-- with status >= 200 (ngx.HTTP_OK) and status < 300 (ngx.HTTP_SPECIAL_RESPONSE) for successful quits
			--	*) see: https://www.nginx.com/resources/wiki/modules/lua/#ngx-exit
			local ok = status >= 200 and status < 300
			if not ok then return Promise.reject({index = left+j, reason = resp}) end -- fake reject
			table.insert(results, left+j, resp)
		end
	end

	-- return Promise.resolve(results) -- fake resolve
	return results
end

return {
	distributed_request = distributed_request
}