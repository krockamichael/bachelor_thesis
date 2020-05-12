------------------------------------------------------------------------------------
-- a resource center for debug/demo only
------------------------------------------------------------------------------------
return {
	["require"] = function(parts)
		if parts == 'test:local' then
			local local_execute_uri = "http://" .. ngx.var.server_addr .. ":" .. ngx.var.server_port .. "/execute?"
			return { local_execute_uri }
		end
	end
}