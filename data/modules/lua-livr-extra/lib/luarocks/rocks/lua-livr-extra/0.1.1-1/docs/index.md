
# lua-LIVR-extra

---

## Overview

This module is a [lua-LIVR](https://fperrad.frama.io/lua-LIVR) add-on,
its implements more [LIVR](http://livr-spec.org) rules.

Theses rules (with their test suite) come from [js-livr-extra-rules](https://github.com/koorchik/js-livr-extra-rules).

## Status

lua-LIVR-extra is in beta stage.

It's developed for Lua 5.1, 5.2 & 5.3.

## Download

lua-LIVR-extra source can be downloaded from
[Framagit](https://framagit.org/fperrad/lua-LIVR-extra).

## Installation

lua-LIVR-extra depends on
[lua-LIVR](https://fperrad.frama.io/lua-LIVR).

lua-LIVR-extra is available via LuaRocks:

```sh
luarocks install lua-livr-extra
```

or manually, with:

```sh
make install
```

## Test

The test suite requires the modules
[lua-TestMore](https://fperrad.frama.io/lua-TestMore/),
[dkjson](http://dkolf.de/src/dkjson-lua.fsl/home) &
[LuaFileSystem](https://keplerproject.github.io/luafilesystem/).

    make test

## Copyright and License

Copyright &copy; 2018-2019 Fran&ccedil;ois Perrad

This library is licensed under the terms of the MIT/X11 license, like Lua itself.
