# lua-jconv


[jconv](https://github.com/narirou/jconv)のLua Portです。


# 依存
[bit32](https://luarocks.org/modules/siffiejoe/bit32) >= 5.3.0-1

# インストール
`$ luarocks install lua-jconv`

# 使い方
```lua
local jconv = require "jconv"
require "buffer"

function readFileSync(filePath)
	local buffer = {}

	f = io.open(filePath, "rb")

	while true do
		local byte = f:read(1)
		if not byte then break end
		for c in (byte or ''):gmatch'.' do
			buffer[#buffer + 1] = c:byte()
		end
	end

	f:close()

	return buffer
end

local tmp = readFileSync("./sjis.txt")

local utf_8_string = jconv.convert(Buffer.new(tmp), "SJIS", "UTF8")

print(utf_8_string:toString())
```

# API
* jconv.convert(input, fromEncoding, toEncoding)
