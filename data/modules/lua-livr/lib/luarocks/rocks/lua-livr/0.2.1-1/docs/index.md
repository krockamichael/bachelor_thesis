
# lua-LIVR

---

## Overview

lua-LIVR is a lightweight validator supporting Language Independent Validation Rules Specification (LIVR).

Features:

- Rules are declarative and language independent
- Any number of rules for each field
- Return together errors for all fields
- Excludes all fields that do not have validation rules described
- Has possibility to validatate complex hierarchical structures
- Easy to describe and undersand rules
- Returns understandable error codes(not error messages)
- Easy to add own rules
- Multipurpose (user input validation, configs validation, contracts programming etc)

## References

The LIVR specifications are available on <http://livr-spec.org/>.

## Status

lua-LIVR is in beta stage.

It's developed for Lua 5.1, 5.2 & 5.3.

## Download

lua-LIVR source can be downloaded from
[Framagit](https://framagit/fperrad/lua-LIVR).

## Installation

lua-LIVR have two optional dependencies
[lua-utf8](https://github.com/starwing/luautf8) &
[Lrexlib-PCRE](https://rrthomas.github.io/lrexlib/).

lua-LIVR is available via LuaRocks:

```sh
luarocks install lua-livr
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
