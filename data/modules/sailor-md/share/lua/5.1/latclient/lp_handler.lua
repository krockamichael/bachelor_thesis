-- This file is part of the Lua@Client project
-- Copyright (c) 2014 Felipe Daragon
-- License: MIT

function handle_lp(r)
	local lp = require "latclient.lp_mod"
	r.content_type = "text/html"
	puts = function(s) r:write(s) end
	lp.setoutfunc "puts"
	lp.include(r.filename)
end

function provide_file(r)
	local conf = require "latclient.conf"
	local vm = require("latclient."..conf.lua_at_client.vm)
	return vm.handle(r)
end