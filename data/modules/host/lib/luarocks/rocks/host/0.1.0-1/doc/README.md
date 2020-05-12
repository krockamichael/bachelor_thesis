# lua-host

Constants about host os/arch/bits/endian for Lua.

## Usage

> luarocks install host

``lua
local host = require('host')
print(host.os)
print(host.arch)
print(host.bits)
print(host.endian)
```

`host.os`:

- 'Windows'
- 'Linux'
- 'OSX'
- 'BSD'
- 'POSIX'
- 'Other'

`host.arch`:

- 'x86'
- 'x64'
- 'arm'
- 'arm64'
- 'ppc64le'
- 'ppc64'
- 'ppc'
- 'mipsel'
- 'mips'

`host.bits`:

- 32
- 64

`host.endian`:

- 'little'
- 'big'


## Thanks

The source file `lj_arch.h` is doing the main host detecting job at the compile time.
And it's taken form the [LuaJIT](http://luajit.org/luajit.html) version 2.1.0 beta2 code.

Thanks the LuaJIT authors and contributors.
