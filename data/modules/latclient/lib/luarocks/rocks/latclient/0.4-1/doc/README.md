# Lua@Client #

Lua@Client is focused in helping bring the Lua programming language to the web and browser. This project extends the .lp preprocessor to add support for new opening tags:

`<?lua@client`, `<?lua@server`, and `<?lua@both`.

The tag `<?lua@client` converts the code to client-side Lua, `<?lua@server` works the same as `<?lua` without the @ complement, and `<?lua@both` allows to mix client and server-side Lua code.

Lua@Client can be used with mod_lua, CGILua and projects that use the `lp.lua` library. It is also integrated and bundled with the latest release of the [Sailor MVC Lua Framework](https://github.com/Etiene/sailor).

To make the client-side Lua usage possible, the project integrates and extends a Lua VM allowing usage of browser-specific JavaScript objects (such as `document`, `window`, etc) from Lua. Currently, four different VMs are supported. You can also use Lua@Client without any preprocessors, from static HTML pages (see the examples folder for some simple example usage).

Lua@Client also provides on-the-fly conversion of Lua modules to JavaScript.

## Development Status #

This project is still beta. All input, feedback and contributions are highly appreciated.

##Installation

###Installation for Apache with mod_lua

1. Copy the JavaScript files from the `js` directory in this repository to a public area of your website.
2. Change the vm_url value in `latclient\conf.lua`. It must point to the URL where your copy of the JS files can be found.
3. Copy `latclient.lua` and the `latclient` subdirectory (which contains the lp_*.lua files) to the lua directory.
4. Edit the Apache httpd.conf file and add:

```
LuaMapHandler "\.lp$" "path/to/lua/latclient/lp_handler.lua" handle_lp
```

Done! You can start using `<?lua@` in .lp files.

####Note about FallbackResource

With Apache HTTPd <2.4.9, the FallbackResource directive should preferably not be used in the active virtual host, as it invalidates the LuaMapHandler directive.

###Installation with Sailor

Lua@Client comes bundled with the [Sailor MVC Lua Framework](https://github.com/Etiene/sailor), so you may prefer this route. Sailor is currently compatible with Apache with mod_lua or mod_pLua, Nginx with ngx_lua, Lwan, Lighttpd with mod_magnet, or any CGI-enabled web server, like Civetweb, Mongoose and Xavante, if CGILua is present.

[Install Sailor](https://github.com/Etiene/sailor#installation), merge the `test/dev-app` application with the default Sailor app, and simply point your browser to `?r=test/starlight` to see it in action.

###Installation for CGILua

1. Copy the JavaScript files from the `js` directory in this repository to a public area of your website.
2. Change the vm_url value in `latclient\conf.lua`. It must point to the URL where your copy of the JS files can be found.
3. Copy `latclient.lua` and the latclient directory contents to the lua directory.
4. Edit `cgilua\lp.lua` and: add `local lat = require "latclient"` to the beginning of the file and add `s = lat.translate(s)` as the first line of the translate function (see the [lp_mod.lua](https://github.com/felipedaragon/lua_at_client/blob/master/lua/latclient/lp_mod.lua) file for an example).

Done! You can create your first .lp script using `<?lua@`

## Usage Examples #

Lua@Client usage will vary slightly according to the assigned Lua VM.

For starlight or moonshine, see [LUA_AT_CLIENT.starlight.md](https://github.com/felipedaragon/lua_at_client/blob/master/docs/LUA_AT_CLIENT.starlight.md)

For lua51js, see [LUA_AT_CLIENT.lua51js.md](https://github.com/felipedaragon/lua_at_client/blob/master/docs/LUA_AT_CLIENT.lua51js.md)

For luavmjs, see [LUA_AT_CLIENT.luavmjs.md](https://github.com/felipedaragon/lua_at_client/blob/master/docs/LUA_AT_CLIENT.luavmjs.md)

As of the current release, starlight is the default recommended VM to run client-side scripts - you can change the VM by editing the `conf.lua` file.

For a comparison between the different VMs, see [here](https://github.com/Etiene/sailor/blob/master/docs/manual_lua_at_client.md)

## License #

Lua@Client is licensed under the [MIT license](http://opensource.org/licenses/MIT)

(c) Felipe Daragon, 2014

Lua@Client contains the following MIT-licensed, third-party code:

* Copyright (c) 2015 Paul Cuthbertson - Starlight
* Copyright (c) 2013-2015 Gamesys Limited - Moonshine
* Copyright (c) 2013-2014 Alon Zakai (kripken) and Daurnimator - Lua.vm.js
* Copyright (c) LogicEditor <info@logiceditor.com>, and lua5.1.js authors - lua5.1.js project files, based on Lua.
* Copyright (c) 2013 [Kevin van Zonneveld](http://kvz.io) and [Contributors](http://phpjs.org/authors) - base64 decode function for JavaScript
* Copyright (c) 2011 Josh Tynjala - getset Lua library
* Copyright (c) 1994-2012 Lua.org, PUC-Rio - Lua