# tundrawolf

tundrawolf is implement of PEDT - Parallel Exchangeable Distribution Task specifications for nginx_lua.

PEDT v1.1 specifications supported.

### Table of Contents

* [install](#install)
* [configurations in nginx.conf](#configurations-in-nginxconf)
* [import and usage](#import-and-usage)
  * [options](#options)
  * [interfaces](#interfaces)
* [helpers](#helpers)
  * [Tundrawolf.infra.taskhelper](#tundrawolfinfrataskhelper)
  * [Tundrawolf.infra.httphelper](#tundrawolfinfrahttphelper)
  * [Tundrawolf.infra.requestdata](#tundrawolfinfrarequestdata)
  * [tundrawolf.dbg.*](#tundrawolfdbg)
* [system route discoveries in tundrawolf](#system-route-discoveries-in-tundrawolf)
* [testcase](#testcase)
* [history](#history)

# install

> git clone https://github.com/aimingoo/tundrawolf

or

> luarocks install tundrawolf

# configurations in nginx.conf

First, append path to nginx.conf:

``` conf
http {
	lua_package_path '...;${YOUR_Tundrawolf_DIR}/?.lua;;';
	...
```

> note1: you can skip package_path setting when tundrawolf installed by luarocks
> 
> note2: @see $(Tundrawolf)/nginx/conf/nginx.conf

And next, add proxy_pass_interface in locatoin part:

``` conf
http {
	...
	server {
		...
		location ~ ^/_/cast {
			## for default distributed_request interface in infra.httphelper, copy from:
			## 	$(Tundrawolf)/nginx/conf/nginx.conf
		}
```

for custom distributed_request interface/location, please copy $(tundrawolf)/infra/httphelper.lua to your project, change it and update location in nginx.conf.

# import and usage

Loading Tundrawolf into your source code:

``` lua
-- require when installed by luarocks
local Tundrawolf = require('tundrawolf');

-- or hard load from lua_path/directory
-- local Tundrawolf = require('lib.Distributed');

local options = {};
local pedt = Tundrawolf:new(options);

pedt:run(..)
	:andThen(function(result){
		..
	})
```

## options

the full options schema:

``` lua
options = {
	distributed_request = function(arrResult) .. end, -- a http client implement
	system_route = { .. }, -- any key/value pairs
	task_register_center = {
		download_task = function(taskId) .. end, -- PEDT interface
		register_task = function(taskDef) .. end,  -- PEDT interface
	},
	resource_status_center = {
		require = function(resId) .. end,-- PEDT interface
	}
}
```

## interfaces

> for detail, @see ${tundrawolf}/infra/specifications/*
> 
> for Promise in lua, @see [https://github.com/aimingoo/Promise](https://github.com/aimingoo/Promise)

all interfaces are promise supported except pedt.upgrade() and helpers.

all implements is harpseal based, @see [https://github.com/aimingoo/harpseal#interfaces](https://github.com/aimingoo/harpseal#interfaces)

# helpers

some tool/helpers include in the package.

## Tundrawolf.infra.taskhelper

``` lua
local Tundrawolf = require('tundrawolf');
local def = Tundrawolf.infra.taskhelper;
-- or
-- local def = require('tundrawolf.infra.taskhelper');

local taskDef = {
	x = def:run(...),
	y = def:map(...),
	...
}
```

a taskDef define helper.

## Tundrawolf.infra.httphelper

``` lua
local Tundrawolf = require('tundrawolf');
local httphelper = Tundrawolf.infra.httphelper;
-- or
-- local httphelper = require('tundrawolf.infra.httphelper');

local options = {
	...,
	distributed_request = httphelper.distributed_request
}
```

a recommented/standard distributed request. @see:

> ${tundrawolf}/demo.lua

## Tundrawolf.infra.requestdata

``` lua
local Tundrawolf = require('tundrawolf');
local requestdata = Tundrawolf.infra.requestdata;
-- or
-- local requestdata = require('tundrawolf.infra.requestdata');

...
local arguments = requestdata.parse()
n4c:execute_task(taskId, arguments)
```

parse arguments of PEDT task from http request. @see

> ${ngx_4c}/module/n4c_executor.lua

## tundrawolf.dbg.*

these are debug interfaces, please require/load as filemodule, or install by luarocks. @see:

> ${tundrawolf}/demo.lua

# system route discoveries in tundrawolf

in tundrawolf, you can register and discovery any system resources. for examples:

``` lua
-- got system route discoveries
local Tundrawolf = require('tundrawolf')
local pedt = Tundrawolf:new({})
local system_route_discoveries = pedt:require('n4c.system.discoveries)

-- put your resources
local a_key, my_resource = "MY:RESOURCE_KEY", {} -- or anythings except false/nil in nginx_lua
local discoveries = {
	[a_key] = function() return my_resource end,
	-- more
}
table.foreach(discoveries, function(key, discoverer)
	system_route_discoveries[key] = discoverer
end)

-- usage
local res = pedt:require("MY:RESOURCE_KEY") -- a_key
```

all keys were cached always, so discoverer function call once  until you manual set invalid a_key:

``` lua
pedt.upgrade({system_route = {[a_key] = false}})
```

for more example, @see [aimingoo/ngx_4c project](https://github.com/aimingoo/ngx_4c).

# testcase

try these:

``` bash
> # goto home directory
> cd ~
> git clone 'https://github.com/aimingoo/tundrawolf'

> # goto nginx install direcotry
> # 	cd {$NGINX_HOME}/sbin
> ./nginx -p "${HOME}/tundrawolf/nginx"

> # goback and launch testcase
> go ~/tundrawolf/testcase
> bash test.sh
```

# history

``` text
2015.12.03	v1.0.4 released.
	- sync to Harpseal v1.0.4
2015.11.14	v1.0.1 released.
	- Tundrawolf.infra.requestdata interface published.
	- to be compatible ngx_cc at proxy_pass_interface.
2015.11.09	v1.0.0 released.
```