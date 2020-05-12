local popen = io.popen
local site_config = {}
site_config.LUAROCKS_PREFIX=[[/home/michael/luadb/etc/luarocks_test/modules/luapak]]
site_config.LUA_INCDIR=[[/usr/include/lua5.1]]
site_config.LUA_LIBDIR=[[/usr/local/lib]]
site_config.LUA_BINDIR=[[/usr/bin]]
site_config.LUA_INTERPRETER=[[lua5.1]]
site_config.LUAROCKS_SYSCONFDIR=[[/etc/luarocks]]
site_config.LUAROCKS_ROCKS_TREE=[[/usr/local/]]
site_config.LUAROCKS_ROCKS_SUBDIR=[[/lib/luarocks/rocks]]
site_config.LUA_DIR_SET=true
site_config.LUAROCKS_UNAME_S=(popen("uname -s"):read("*a"):gsub("\n",""))
site_config.LUAROCKS_UNAME_M=(popen("uname -m"):read("*a"):gsub("\n",""))
site_config.LUAROCKS_DOWNLOADER=[[wget]]
site_config.LUAROCKS_MD5CHECKER=[[md5sum]]
site_config.LUAROCKS_EXTERNAL_DEPS_SUBDIRS={ bin="bin", lib={ "lib", [[lib/x86_64-linux-gnu]] }, include="include" }
site_config.LUAROCKS_RUNTIME_EXTERNAL_DEPS_SUBDIRS={ bin="bin", lib={ "lib", [[lib/x86_64-linux-gnu]] }, include="include" }
return site_config
