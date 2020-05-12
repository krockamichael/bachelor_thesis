------------------------------------------------------------------------------------
-- a register center for debug/demo only
------------------------------------------------------------------------------------
local MD5 = ngx.md5
local dbg_storage = {}

return {
	download_task = function(taskId)
		return dbg_storage[string.gsub(taskId, '^task:', "")]
	end,

	register_task = function(taskDef)
		local id = MD5(tostring(taskDef))
		dbg_storage[id] = taskDef
		return 'task:' .. id
	end,

	-- statistics only
	report = function()
		local JSON = require('cjson')
		local JSON_decode = JSON.decode
		local JSON_encode = JSON.encode
		print('=============================================')
		print('OUTPUT dbg_storage');
		print('=============================================')
		table.foreach(dbg_storage, function(key, value)
			print('==> ', key)
			print(JSON_encode(JSON_decode(value)))
		end)
	end
}