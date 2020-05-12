--[[! ------------------------------------------------------

	lua-jconv

------------------------------------------------------- ]]

local bit32 = require("bit32")
require("buffer")

--------------------------------------------------------

--local s = '・'
local unknown = 12539 --s:byte(1)--'・'.charCodeAt( 0 )

local tables = {
	SJIS=           require( 'tables/SJIS' ),
	JIS=            require( 'tables/JIS' ),
	JISEXT=         require( 'tables/JISEXT' ),
	SJISInverted=   require( 'tables/SJISInverted' ),
	JISInverted=    require( 'tables/JISInverted' ),
	JISEXTInverted= require( 'tables/JISEXTInverted' )
}

local encodings = {}

local _jconv = {}

_jconv.defineEncoding = function( obj )
	local Encoding = function( obj )
		local o = {}
		o.name = obj.name
		o.convert = obj.convert
		return o
	end
	encodings[ obj.name ] = Encoding( obj )
end

_jconv.convert = function( buf, from, to )
	local from = getName( from )
	local to   = getName( to )

	if from == "" or to == "" then
		assert(false, 'Encoding not recognized.' )
	end

	buf = ensureBuffer( buf )

	if from == to then
		return buf
	end

	-- Directly convert if possible.
	local encoder = encodings[ from .. 'to' .. to ]
	if encoder then
		return encoder.convert( buf )
	end

	local uniDecoder = encodings[ from .. 'toUCS2' ]
	local Encoder = encodings[ 'UCS2to' .. to ]
	if uniDecoder and uniEncoder then
		return uniEncoder.convert( uniDecoder.convert( buf ) )
	else
		assert(false, 'Encoding not recognized.' )
	end
end

_jconv.decode = function( buf, from )
	-- Internal Encoding
	if from:upper() == 'BINARY' or from:upper() == 'BASE64' or from:upper() == 'ASCII' or from:upper() == 'HEX' or from:upper() == 'UTF8' or from:upper() == 'UTF-8' or from:upper() == 'UNICODE' or from:upper() == 'UCS2' or from:upper() == 'UCS-2' or from:upper() == 'UTF16LE' or from:upper() == 'UTF-16LE' then
		return buf:toString( from )
	else
		return _jconv.convert( buf, from, 'UCS2' ):toString( 'UCS2' )
	end
end

_jconv.encode = function( str, to )
	-- Internal Encoding
	if to:upper() == 'BASE64' or to:upper() == 'ASCII' or to:upper() == 'HEX' or to:upper() == 'UTF8' or to:upper() == 'UTF-8' then
		return Buffer.new( str, to )
	else
		return _jconv.convert( str, 'UTF8', to )
	end
end

_jconv.encodingExists = function( encoding )
	return getName( encoding ) and true or false
end

function getName( name )
	if name:upper() == 'WINDOWS-31J' or name:upper() == 'CP932' or name:upper() == 'SJIS' or name:upper() == 'SHIFTJIS' or name:upper() == 'SHIFT_JIS' then
		return 'SJIS'
	elseif name:upper() == 'EUCJP' or name:upper() == 'EUC-JP' then
		return 'EUCJP'
	elseif name:upper() == 'JIS' or name:upper() == 'ISO2022JP' or name:upper() == 'ISO-2022-JP' or name:upper() == 'ISO-2022-JP-1' then
		return 'JIS'
	elseif name:upper() == 'UTF8' or name:upper() == 'UTF-8' then
		return 'UTF8'
	elseif name:upper() == 'UNICODE' or name:upper() == 'UCS2' or name:upper() == 'UCS-2' or name:upper() == 'UTF16LE' or name:upper() == 'UTF-16LE' then
		return 'UCS2'
	else
		return false
	end
end

function ensureBuffer( buf )
	if buf == nil then
		return Buffer.new( 0 )
	elseif type(buf) == "string" then
		return Buffer.new( buf )
	elseif type(buf) ~= "table" then
		return Buffer.new( 0 )
	elseif type(buf) == "table" then
		if buf.Buffer == true then
			return buf
		else
			return Buffer.new( 0 )
		end
	else
		return Buffer.new( buf:toString(), 'UTF8' )
	end
end

-- Unicode CharCode -> UTF8 Buffer
function setUtf8Buffer( unicode, utf8Buffer, offset )
	if unicode < 0x80 then
		utf8Buffer:writeAt(offset, unicode)
		offset = offset + 1
	elseif unicode < 0x800 then
		utf8Buffer:writeAt(offset, bit32.bor(0xC0, bit32.rshift(unicode,  6)))
		offset = offset + 1
		utf8Buffer:writeAt(offset, bit32.bor(0x80, bit32.band(unicode, 0x3F)))
		offset = offset + 1
	elseif unicode < 0x10000 then
		utf8Buffer:writeAt(offset, bit32.bor(0xE0, bit32.rshift(unicode, 12)))
		offset = offset + 1
		utf8Buffer:writeAt(offset, bit32.bor(0x80, bit32.band(bit32.rshift(unicode, 6), 0x3F)))
		offset = offset + 1
		utf8Buffer:writeAt(offset, bit32.bor(0x80, bit32.band(unicode, 0x3F)))
		offset = offset + 1
	elseif unicode < 0x200000 then
		utf8Buffer:writeAt(offset, bit32.bor(0xF0, bit32.rshift(unicode, 18)))
		offset = offset + 1
		utf8Buffer:writeAt(offset, bit32.bor(0x80, bit32.rshift(bit32.band(unicode, 12), 0x3F)))
		offset = offset + 1
		utf8Buffer:writeAt(offset, bit32.bor(0x80, bit32.band(bit32.rshift(unicode, 6), 0x3F)))
		offset = offset + 1
		utf8Buffer:writeAt(offset, bit32.bor(0x80, bit32.band(unicode, 0x3F)))
		offset = offset + 1
	elseif unicode < 0x4000000 then
		utf8Buffer:writeAt(offset, bit32.bor(0xF8, bit32.rshift(unicode, 24)))
		offset = offset + 1
		utf8Buffer:writeAt(offset, bit32.bor(0x80, bit32.rshift(bit32.band(unicode, 18, 0x3F))))
		offset = offset + 1
		utf8Buffer:writeAt(offset, bit32.bor(0x80, bit32.rshift(bit32.band(unicode, 12), 0x3F)))
		offset = offset + 1
		utf8Buffer:writeAt(offset, bit32.bor(0x80, bit32.band(bit32.rshift(unicode, 6), 0x3F)))
		offset = offset + 1
		utf8Buffer:writeAt(offset, bit32.bor(0x80, bit32.band(unicode, 0x3F)))
		offset = offset + 1
	else
		utf8Buffer:writeAt(offset, bit32.bor(0xFC, unicode  / 0x40000000))
		offset = offset + 1
		utf8Buffer:writeAt(offset, bit32.bor(0x80, bit32.rshift(bit32.band(unicode, 24, 0x3F))))
		offset = offset + 1
		utf8Buffer:writeAt(offset, bit32.bor(0x80, bit32.rshift(bit32.band(unicode, 18, 0x3F))))
		offset = offset + 1
		utf8Buffer:writeAt(offset, bit32.bor(0x80, bit32.rshift(bit32.band(unicode, 12), 0x3F)))
		offset = offset + 1
		utf8Buffer:writeAt(offset, bit32.bor(0x80, bit32.band(bit32.rshift(unicode, 6), 0x3F)))
		offset = offset + 1
		utf8Buffer:writeAt(offset, bit32.bor(0x80, bit32.band(unicode, 0x3F)))
		offset = offset + 1
	end
	return offset
end

function setUnicodeBuffer( unicode, unicodeBuffer, offset )
	unicodeBuffer:writeAt(offset, bit32.band(unicode, 0xFF))
	offset = offset + 1

	unicodeBuffer:writeAt(offset, bit32.arshift(unicode, 8))
	offset = offset + 1
	return offset
end

-- UCS2 = UTF16LE(no-BOM)
-- UCS2 -> UTF8
_jconv.defineEncoding({
	name = 'UCS2toUTF8',

	convert = function( buf )
		local setUtf8Buf = setUtf8Buffer

		local len     = buf:length()
		local utf8Buf = Buffer.new( len * 3 )
		local offset  = 0
		local unicode

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1
			local buf2 = buf:at(i)
			i = i + 1

			unicode = ( bit32.lshift(buf2, 8) ) + buf1

			offset = setUtf8Buf( unicode, utf8Buf, offset )
		end
		return utf8Buf:slice( 0, offset )
	end
})

-- UCS2 -> SJIS
_jconv.defineEncoding({
	name = 'UCS2toSJIS',

	convert = function( buf )
		local tableSjisInv = tables[ 'SJISInverted' ]
		local unknownSjis  = tableSjisInv[ unknown ]

		local len     = buf:length()
		local sjisBuf = Buffer.new( len )
		local offset  = 0
		local unicode

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1
			local buf2 = buf:at(i)
			i = i + 1

			unicode = ( bit32.lshift(buf2, 8) ) + buf1

			-- ASCII
			if unicode < 0x80 then
				sjisBuf:writeAt(offset, unicode)
				offset = offset + 1
			-- HALFWIDTH_KATAKANA
			elseif 0xFF61 <= unicode and unicode <= 0xFF9F then
				sjisBuf:writeAt(offset, unicode - 0xFEC0)
				offset = offset + 1
			-- KANJI
			else
				local code = tableSjisInv[ unicode ] or unknownSjis
				sjisBuf:writeAt(offset, bit32.arshift(code, 8))
				offset = offset + 1
				sjisBuf:writeAt(offset, bit32.band(code, 0xFF))
				offset = offset + 1
			end
		end
		return sjisBuf:slice( 0, offset )
	end
})

-- UCS2 -> JIS
_jconv.defineEncoding({
	name = 'UCS2toJIS',

	convert = function( buf )
		local tableJisInv    = tables[ 'JISInverted' ]
		local tableJisExtInv = tables[ 'JISEXTInverted' ]
		local unknownJis     = tableJisInv[ unknown ]

		local len      = buf:length()
		local jisBuf   = Buffer.new( len * 3 + 4 )
		local offset   = 0
		local unicode
		local sequence = 0

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1
			local buf2 = buf:at(i)
			i = i + 1

			unicode = ( bit32.lshift(buf2, 8) ) + buf1

			-- ASCII
			if unicode < 0x80 then
				if sequence ~= 0 then
					sequence = 0
					jisBuf:writeAt(offset, 0x1B)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x28)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x42)
					offset = offset + 1
				end
				jisBuf:writeAt(offset, unicode)
				offset = offset + 1
			-- HALFWIDTH_KATAKANA
			elseif 0xFF61 <= unicode and unicode <= 0xFF9F then
				if sequence ~= 1 then
					sequence = 1
					jisBuf:writeAt(offset, 0x1B)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x28)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x49)
					offset = offset + 1
				end
				jisBuf:writeAt(offset, unicode - 0xFF40)
				offset = offset + 1
			else
				local code = tableJisInv[ unicode ]
				if code then
					-- KANJI
					if sequence ~= 2 then
						sequence = 2
						jisBuf:writeAt(offset, 0x1B)
						offset = offset + 1
						jisBuf:writeAt(offset, 0x24)
						offset = offset + 1
						jisBuf:writeAt(offset, 0x42)
						offset = offset + 1
					end
					jisBuf:writeAt(offset, bit32.arshift(code, 8))
					offset = offset + 1
					jisBuf:writeAt(offset, bit32.band(code, 0xFF))
					offset = offset + 1
				else
					local ext = tableJisExtInv[ unicode ]
					if ext then
						-- EXTENSION
						if sequence ~= 3 then
							sequence = 3
							jisBuf:writeAt(offset, 0x1B)
							offset = offset + 1
							jisBuf:writeAt(offset, 0x24)
							offset = offset + 1
							jisBuf:writeAt(offset, 0x28)
							offset = offset + 1
							jisBuf:writeAt(offset, 0x44)
							offset = offset + 1
						end
						jisBuf:writeAt(offset, bit32.arshift(ext, 8))
						offset = offset + 1
						jisBuf:writeAt(offset, bit32.band(ext, 0xFF))
						offset = offset + 1
					else
						-- UNKNOWN
						if sequence ~= 2 then
							sequence = 2
							jisBuf:writeAt(offset, 0x1B)
							offset = offset + 1
							jisBuf:writeAt(offset, 0x24)
							offset = offset + 1
							jisBuf:writeAt(offset, 0x42)
							offset = offset + 1
						end
						jisBuf:writeAt(offset, bit32.arshift(unknownJis, 8))
						offset = offset + 1
						jisBuf:writeAt(offset, bit32.band(unknownJis, 0xFF))
						offset = offset + 1
					end
				end
			end
		end

		-- Add ASCII ESC
		if sequence ~= 0 then
			sequence = 0
			jisBuf:writeAt(offset, 0x1B)
			offset = offset + 1
			jisBuf:writeAt(offset, 0x28)
			offset = offset + 1
			jisBuf:writeAt(offset, 0x42)
			offset = offset + 1
		end
		return	jisBuf:slice( 0, offset )
	end
})

-- UCS2 -> EUCJP
_jconv.defineEncoding({
	name = 'UCS2toEUCJP',

	convert = function( buf )
		local tableJisInv    = tables[ 'JISInverted' ]
		local tableJisExtInv = tables[ 'JISEXTInverted' ]
		local unknownJis     = tableJisInv[ unknown ]

		local len     = buf:length()
		local eucBuf  = Buffer.new( len * 2 )
		local offset  = 0
		local unicode

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1
			local buf2 = buf:at(i)
			i = i + 1

			unicode = ( bit32.lshift(buf2, 8) ) + buf1

			-- ASCII
			if unicode < 0x80 then
				eucBuf:writeAt(offset, unicode)
				offset = offset + 1
			-- HALFWIDTH_KATAKANA
			elseif 0xFF61 <= unicode and unicode <= 0xFF9F then
				eucBuf:writeAt(offset, 0x8E)
				offset = offset + 1
				eucBuf:writeAt(offset, unicode - 0xFFC0)
				offset = offset + 1
			else
				-- KANJI
				local jis = tableJisInv[ unicode ]
				if jis then
					eucBuf:writeAt(offset, ( bit32.arshift(jis,8) ) - 0x80)
					offset = offset + 1
					eucBuf:writeAt(offset, ( bit32.band(jis, 0xFF) ) - 0x80)
					offset = offset + 1
				else
					-- EXTENSION
					local ext = tableJisExtInv[ unicode ]
					if ext then
						eucBuf:writeAt(offset, 0x8F)
						offset = offset + 1
						eucBuf:writeAt(offset, ( bit32.arshift(ext, 8) ) - 0x80)
						offset = offset + 1
						eucBuf:writeAt(offset, ( bit32.band(ext, 0xFF) ) - 0x80)
						offset = offset + 1
					-- UNKNOWN
					else
						eucBuf:writeAt(offset, ( bit32.arshift(unknownJis, 8) ) - 0x80)
						offset = offset + 1
						eucBuf:writeAt(offset, ( bit32.band(unknownJis, 0xFF) ) - 0x80)
						offset = offset + 1
					end
				end
			end
		end
		return eucBuf:slice( 0, offset )
	end
})

-- UTF8 -> UCS2
_jconv.defineEncoding({
	name = 'UTF8toUCS2',

	convert = function( buf )
		local setUnicodeBuf = setUnicodeBuffer

		local len        = buf:length()
		local unicodeBuf = Buffer.new( len * 2 )
		local offset     = 0
		local unicode

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1

			local s = (bit32.arshift(buf1, 4))
			if s == 0 or s == 1 or s == 2 or s == 3 or s == 4 or s == 5 or s == 6 or s == 7 then
				unicode = buf1
			elseif s == 12 or s == 13 then
				unicode = bit32.lshift((bit32.band(buf1, 0x1F)),  6)
				unicode = bit32.bor(unicode, bit32.band(buf:at(i), 0x3F))
				i = i + 1
			elseif s == 14 then
				local a = bit32.lshift(bit32.band(buf1, 0x0F), 12)
				local b = bit32.lshift(bit32.band(buf:at(i), 0x3F), 6)
				i = i + 1
				local c = bit32.band(buf:at(i), 0x3F)
				i = i + 1
				unicode = bit32.bor(bit32.bor(a, b), c)
			else
				local a = bit32.lshift(bit32.band(buf1, 0x07), 18)
				local b = bit32.lshift(bit32.band(buf:at(i), 0x3F), 12)
				i = i + 1
				local c = bit32.lshift(bit32.band(buf:at(i), 0x3F), 6)
				i = i + 1
				local d = bit32.band(buf:at(i), 0x3F)
				i = i + 1
				unicode = bit32.bor(bit32.bor(bit32.bor(a, b), c), d)
			end
			offset = setUnicodeBuffer( unicode, unicodeBuf, offset )
		end
		return unicodeBuf:slice( 0, offset )
	end
})

-- UTF8 -> SJIS
_jconv.defineEncoding({
	name = 'UTF8toSJIS',

	convert = function( buf )
		local tableSjisInv = tables[ 'SJISInverted' ]
		local unknownSjis  = tableSjisInv[ unknown ]

		local len     = buf:length()
		local sjisBuf = Buffer.new( len * 2 )
		local offset  = 0
		local unicode

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1

			if (bit32.arshift(buf1, 4)) == 0 or (bit32.arshift(buf1, 4)) == 1 or (bit32.arshift(buf1, 4)) == 2 or (bit32.arshift(buf1, 4)) == 3 or (bit32.arshift(buf1, 4)) == 4 or (bit32.arshift(buf1, 4)) == 5 or (bit32.arshift(buf1, 4)) == 6 or (bit32.arshift(buf1, 4)) == 7 then
				unicode = buf1
			elseif (bit32.arshift(buf1, 4)) == 12 or (bit32.arshift(buf1, 4)) == 13 then
				unicode = bit32.lshift((bit32.band(buf1, 0x1F)),  6)
				unicode = bit32.bor(unicode, bit32.band(buf:at(i), 0x3F))
				i = i + 1
			elseif (bit32.arshift(buf1, 4)) == 14 then
				unicode = bit32.lshift(bit32.band(buf1, 0x0F), 12)
				unicode = bit32.bor(unicode, bit32.lshift(bit32.band(buf:at(i), 0x3F), 6))
				i = i + 1
				unicode = bit32.bor(unicode, bit32.band(buf:at(i), 0x3F))
				i = i + 1
			else
				unicode = bit32.lshift((bit32.band(buf1, 0x07)), 18)
				unicode = bit32.bor(unicode, bit32.lshift((bit32.band(buf:at(i), 0x3F)), 12))
				i = i + 1
				unicode = bit32.bor(unicode, bit32.lshift((bit32.band(buf:at(i), 0x3F)), 6))
				i = i + 1
				unicode = bbit32.bor(it32.band(unicode, buf:at(i), 0x3F))
				i = i + 1
			end

			-- ASCII
			if unicode < 0x80 then
				sjisBuf:writeAt(offset, unicode)
				offset = offset + 1
			-- HALFWIDTH_KATAKANA
			elseif 0xFF61 <= unicode and unicode <= 0xFF9F then
				sjisBuf:writeAt(offset, unicode - 0xFEC0)
				offset = offset + 1
			-- KANJI
			else
				local code = tableSjisInv[ unicode ] or unknownSjis
				sjisBuf:writeAt(offset, bit32.arshift(code, 8))
				offset = offset + 1
				sjisBuf:writeAt(offset, bit32.band(code, 0xFF))
				offset = offset + 1
			end
		end
		return sjisBuf:slice( 0, offset )
	end
})

-- UTF8 -> JIS
_jconv.defineEncoding({
	name = 'UTF8toJIS',

	convert = function( buf )
		local tableJisInv    = tables[ 'JISInverted' ]
		local tableJisExtInv = tables[ 'JISEXTInverted' ]
		local unknownJis     = tableJisInv[ unknown ]

		local len      = buf:length()
		local jisBuf   = Buffer.new( len * 3 + 4 )
		local offset   = 0
		local unicode
		local sequence = 0

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1

			local s = bit32.arshift(buf1, 4)
			if s == 0 or s == 1 or s == 2 or s == 3 or s == 4 or s == 5 or s == 6 or s == 7 then
				unicode = buf1
			elseif s == 12 or s == 13 then
				--unicode = (buf1 & 0x1F) <<  6 | buf[ i++ ] & 0x3F;
				unicode = bit32.lshift(bit32.band(buf1, 0x1F), 6)
				unicode = bit32.bor(unicode, bit32.band(buf:at(i), 0x3F))
				i = i + 1
			elseif s == 14 then
				--unicode = (buf1 & 0x0F) << 12 | (buf[ i++ ] & 0x3F) <<  6 | buf[ i++ ] & 0x3F;
				unicode = bit32.lshift(bit32.band(buf1, 0x0F), 12)
				unicode = bit32.bor(unicode, bit32.lshift(bit32.band(buf:at(i), 0x3F), 6))
				i = i + 1
				unicode = bit32.bor(unicode, bit32.band(buf:at(i), 0x3F))
				i = i + 1
			else
				--unicode = (buf1 & 0x07) << 18 | (buf[ i++ ] & 0x3F) << 12 | (buf[ i++ ] & 0x3F) << 6 | buf[ i++ ] & 0x3F;
				unicode = bit32.lshift(bit32.band(buf1, 0x07), 18)
				unicode = bit32.bor(unicode, bit32.lshift(bit32.band(buf:at(i), 0x3F), 12))
				i = i + 1
				unicode = bit32.bor(unicode, bit32.lshift(bit32.band(buf:at(i), 0x3F), 6))
				i = i + 1
				unicode = bit32.bor(unicode, bit32.band(buf:at(i), 0x3F))
				i = i + 1
			end
			-- ASCII
			if unicode < 0x80 then
				if sequence ~= 0 then
					sequence = 0
					jisBuf:writeAt(offset, 0x1B)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x28)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x42)
					offset = offset + 1
				end
				jisBuf:writeAt(offset, unicode)
				offset = offset + 1
			-- HALFWIDTH_KATAKANA
			elseif 0xFF61 <= unicode and unicode <= 0xFF9F then
				if sequence ~= 1 then
					sequence = 1
					jisBuf:writeAt(offset, 0x1B)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x28)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x49)
					offset = offset + 1
				end
				jisBuf:writeAt(offset, unicode - 0xFF40)
				offset = offset + 1
			else
				local code = tableJisInv[ unicode ]
				if code then
					-- KANJI
					if sequence ~= 2 then
						sequence = 2
						jisBuf:writeAt(offset, 0x1B)
						offset = offset + 1
						jisBuf:writeAt(offset, 0x24)
						offset = offset + 1
						jisBuf:writeAt(offset, 0x42)
						offset = offset + 1
					end
					jisBuf:writeAt(offset, bit32.arshift(code, 8))
					offset = offset + 1
					jisBuf:writeAt(offset, bit32.band(code, 0xFF))
					offset = offset + 1
				else
					local ext = tableJisExtInv[ unicode ]
					if ext then
						-- EXTENSION
						if sequence ~= 3 then
							sequence = 3
							jisBuf:writeAt(offset, 0x1B)
							offset = offset + 1
							jisBuf:writeAt(offset, 0x24)
							offset = offset + 1
							jisBuf:writeAt(offset, 0x28)
							offset = offset + 1
							jisBuf:writeAt(offset, 0x44)
							offset = offset + 1
						end
						jisBuf:writeAt(offset, bit32.arshift(ext, 8))
						offset = offset + 1
						jisBuf:writeAt(offset, bit32.band(ext, 0xFF))
						offset = offset + 1
					else
						-- UNKNOWN
						if sequence ~= 2 then
							sequence = 2
							jisBuf:writeAt(offset, 0x1B)
							offset = offset + 1
							jisBuf:writeAt(offset, 0x24)
							offset = offset + 1
							jisBuf:writeAt(offset, 0x42)
							offset = offset + 1
						end
						jisBuf:writeAt(offset, bit32.arshift(unknownJis, 8))
						offset = offset + 1
						jisBuf:writeAt(offset, bit32.band(unknownJis, 0xFF))
						offset = offset + 1
					end
				end
			end
		end

		-- Add ASCII ESC
		if sequence ~= 0 then
			sequence = 0
			jisBuf:writeAt(offset, 0x1B)
			offset = offset + 1
			jisBuf:writeAt(offset, 0x28)
			offset = offset + 1
			jisBuf:writeAt(offset, 0x42)
			offset = offset + 1
		end
		return jisBuf:slice( 0, offset )
	end
})

-- UTF8 -> EUCJP
_jconv.defineEncoding({
	name = 'UTF8toEUCJP',

	convert = function( buf )
		local tableJisInv    = tables[ 'JISInverted' ]
		local tableJisExtInv = tables[ 'JISEXTInverted' ]
		local unknownJis     = tableJisInv[ unknown ]

		local len     = buf:length()
		local eucBuf  = Buffer.new( len * 2 )
		local offset  = 0
		local unicode

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1

			local s = bit32.arshift(buf1, 4)
			if s == 0 or s == 1 or s == 2 or s == 3 or s == 4 or s == 5 or s == 6 or s == 7 then
				unicode = buf1
			elseif s == 12 or s == 13 then
				unicode = bit32.lshift(bit32.band(buf1, 0x1F), 6)
				unicode = bit32.bor(unicode, bit32.band(buf:at(i), 0x3F))
				i = i + 1
			elseif s == 14 then
				unicode = bit32.lshift(bit32.band(buf1, 0x0F), 12)
				unicode = bit32.bor(unicode, bit32.lshift(bit32.band(buf:at(i), 0x3F), 6))
				i = i + 1
				unicode = bit32.bor(unicode, bit32.band(buf:at(i), 0x3F))
				i = i + 1
			else
				unicode = bit32.lshift(bit32.band(buf1, 0x07), 18)
				unicode = bit32.bor(unicode, bit32.lshift(bit32.band(buf:at(i), 0x3F), 12))
				i = i + 1
				unicode = bit32.bor(unicode, bit32.lshift(bit32.band(buf:at(i), 0x3F),  6))
				i = i + 1
				unicode = bit32.bor(unicode, bit32.band(buf:at(i), 0x3F))
				i = i + 1
			end

			-- ASCII
			if unicode < 0x80 then
				eucBuf:writeAt(offset, unicode)
				offset = offset + 1
			-- HALFWIDTH_KATAKANA
			elseif 0xFF61 <= unicode and unicode <= 0xFF9F then
				eucBuf:writeAt(offset, 0x8E)
				offset = offset + 1
				eucBuf:writeAt(offset, unicode - 0xFFC0)
				offset = offset + 1
			else
				-- KANJI
				local jis = tableJisInv[ unicode ]
				if jis then
					eucBuf:writeAt(offset, ( bit32.arshift(jis,8) ) - 0x80)
					offset = offset + 1
					eucBuf:writeAt(offset, ( bit32.band(jis, 0xFF) ) - 0x80)
					offset = offset + 1
				else
					-- EXTENSION
					local ext = tableJisExtInv[ unicode ]
					if ext then
						eucBuf:writeAt(offset, 0x8F)
						offset = offset + 1
						eucBuf:writeAt(offset, ( bit32.arshift(ext, 8) ) - 0x80)
						offset = offset + 1
						eucBuf:writeAt(offset, ( bit32.band(ext, 0xFF) ) - 0x80)
						offset = offset + 1
					-- UNKNOWN
					else
						eucBuf:writeAt(offset, ( bit32.arshift(unknownJis, 8) ) - 0x80)
						offset = offset + 1
						eucBuf:writeAt(offset, ( bit32.band(unknownJis, 0xFF) ) - 0x80)
						offset = offset + 1
					end
				end
			end
		end
		return eucBuf:slice( 0, offset )
	end
})

-- SJIS -> UCS2
_jconv.defineEncoding({
	name = 'SJIStoUCS2',

	convert = function( buf )
		local tableSjis     = tables[ 'SJIS' ]
		local setUnicodeBuf = setUnicodeBuffer

		local len        = buf:length()
		local unicodeBuf = Buffer.new( len * 3 )
		local offset     = 0
		local unicode

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1

			-- ASCII
			if buf1 < 0x80 then
				unicode = buf1
			-- HALFWIDTH_KATAKANA
			elseif 0xA0 <= buf1 and buf1 <= 0xDF then
				unicode = buf1 + 0xFEC0
			-- KANJI
			else
				local code = ( bit32.lshift(buf1, 8) ) + buf:at(i)
				i = i + 1
				unicode  = tableSjis[ code ] or unknown
			end
			offset = setUnicodeBuffer( unicode, unicodeBuf, offset )
		end
		return unicodeBuf:slice( 0, offset )
	end
})

-- SJIS -> UTF8
_jconv.defineEncoding({
	name = 'SJIStoUTF8',

	convert = function( buf )
		local tableSjis = tables[ 'SJIS' ]
		local setUtf8Buf = setUtf8Buffer;

		local len     = buf:length()
		local utf8Buf = Buffer.new( len * 3 )
		local offset  = 0
		local unicode

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1

			-- ASCII
			if buf1 < 0x80 then
				unicode = buf1
			-- HALFWIDTH_KATAKANA
			elseif 0xA0 <= buf1 and buf1 <= 0xDF then
				unicode = buf1 + 0xFEC0
			-- KANJI
			else
				local code = ( bit32.lshift(buf1, 8) ) + buf:at(i)
				i = i + 1
				unicode  = tableSjis[ code ] or unknown
			end
			offset = setUtf8Buf( unicode, utf8Buf, offset )
		end
		return utf8Buf:slice( 0, offset )
	end
})

-- SJIS -> JIS
_jconv.defineEncoding({
	name = 'SJIStoJIS',

	convert = function( buf )
		local tableSjis   = tables[ 'SJIS' ]
		local tableJisInv = tables[ 'JISInverted' ]

		local len      = buf:length()
		local jisBuf   = Buffer.new( len * 3 + 4 )
		local offset   = 0
		local sequence = 0

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1

			-- ASCII
			if buf1 < 0x80 then
				if sequence ~= 0 then
					sequence = 0
					jisBuf:writeAt(offset, 0x1B)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x28)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x42)
					offset = offset + 1
				end
				jisBuf:writeAt(offset, buf1)
				offset = offset + 1
			-- HALFWIDTH_KATAKANA
			elseif 0xA1 <= buf1 and buf1 <= 0xDF then
				if sequence ~= 1 then
					sequence = 1
					jisBuf:writeAt(offset, 0x1B)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x28)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x49)
					offset = offset + 1
				end
				jisBuf:writeAt(offset, buf1 - 0x80)
				offset = offset + 1
			-- KANJI
			elseif buf1 <= 0xEE then
				if sequence ~= 2 then
					sequence = 2
					jisBuf:writeAt(offset, 0x1B)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x24)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x42)
					offset = offset + 1
				end
				local buf2 = buf:at(i)
				i = i + 1
				buf1 = bit32.lshift(buf1, 1)
				if buf2 < 0x9F then
					if buf1 < 0x13F then
						buf1 = buf1 - 0xE1
					else
						buf1 = buf1 - 0x61
					end
					if buf2 > 0x7E then
						buf2 = buf2 - 0x20
					else
						buf2 = buf2 - 0x1F
					end
				else
					if buf1 < 0x13F then
						buf1 = buf1 - 0xE0
					else
						buf1 = buf1 - 0x60
					end
					buf2 = buf2 - 0x7E
				end
				jisBuf:writeAt(offset, buf1)
				offset = offset + 1
				jisBuf:writeAt(offset, buf2)
				offset = offset + 1
			-- IBM EXTENSION -> the other
			elseif buf1 >= 0xFA then
				if sequence ~= 2 then
					sequence = 2
					jisBuf:writeAt(offset, 0x1B)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x24)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x42)
					offset = offset + 1
				end
				local sjis    = ( bit32.lshift(buf1, 8) ) + buf:at(i)
				i = i + 1
				local unicode = tableSjis[ sjis ] or unknown
				local code    = tableJisInv[ unicode ]

				jisBuf:writeAt(offset, bit32.arshift(code, 8))
				offset = offset + 1
				jisBuf:writeAt(offset, bit32.band(code, 0xFF))
				offset = offset + 1
			end
		end

		-- Add ASCII ESC
		if sequence ~= 0 then
			sequence = 0
			jisBuf:writeAt(offset, 0x1B)
			offset = offset + 1
			jisBuf:writeAt(offset, 0x28)
			offset = offset + 1
			jisBuf:writeAt(offset, 0x42)
			offset = offset + 1
		end
		return jisBuf:slice( 0, offset )
	end
})

-- SJIS -> EUCJP
_jconv.defineEncoding({
	name = 'SJIStoEUCJP',

	convert = function( buf )
		local tableSjis   = tables[ 'SJIS' ]
		local tableJisInv = tables[ 'JISInverted' ]

		local len     = buf:length()
		local eucBuf  = Buffer.new( len * 2 )
		local offset  = 0

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1

			-- ASCII
			if buf1 < 0x80 then
				eucBuf:writeAt(offset, buf1)
				offset = offset + 1
			-- HALFWIDTH_KATAKANA
			elseif 0xA1 <= buf1 and buf1 <= 0xDF then
				eucBuf:writeAt(offset, 0x8E)
				offset = offset + 1
				eucBuf:writeAt(offset, buf1)
				offset = offset + 1
			-- KANJI
			elseif buf1 <= 0xEE then
				local buf2 = buf:at(i)
				i = i + 1
				buf1 = bit32.lshift(buf1, 1)
				if buf2 < 0x9F then
					if buf1 < 0x13F then
						buf1 = buf1 - 0x61
					else
						buf1 = buf1 - 0xE1
					end
					if buf2 > 0x7E then
						buf2 = buf2 + 0x60
					else
						buf2 = buf2 + 0x61
					end
				else
					if buf1 < 0x13F then
						buf1 = buf1 - 0x60
					else
						buf1 = buf1 - 0xE0
					end
					buf2 = buf2 + 0x02
				end
				eucBuf:writeAt(offset, buf1)
				offset = offset + 1
				eucBuf:writeAt(offset, buf2)
				offset = offset + 1
			-- IBM EXTENSION -> the other
			elseif buf1 >= 0xFA then
				local sjis    = ( bit32.lshift(buf1, 8) ) + buf:at(i)
				i = i + 1
				local unicode = tableSjis[ sjis ] or unknown
				local jis     = tableJisInv[ unicode ]

				eucBuf:writeAt(offset, ( bit32.arshift(jis,8) ) - 0x80)
				offset = offset + 1
				eucBuf:writeAt(offset, ( bit32.band(jis, 0xFF) ) - 0x80)
				offset = offset + 1
			end
		end
		return eucBuf:slice( 0, offset )
	end
})

-- JIS -> UCS2
_jconv.defineEncoding({
	name = 'JIStoUCS2',

	convert = function( buf )
		local tableJis    = tables[ 'JIS' ]
		local tableJisExt = tables[ 'JISEXT' ]
		local setUnicodeBuf = setUnicodeBuffer

		local len        = buf:length()
		local unicodeBuf = Buffer.new( len * 2 )
		local offset     = 0
		local unicode
		local sequence   = 0

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1

			-- ESC Sequence
			if buf1 == 0x1b then
				local buf2 = buf:at(i)
				i = i + 1
				local buf3 = buf:at(i)
				i = i + 1

				if buf2 == 0x28 then
					if buf3 == 0x42 or buf:at(i) == 0xA1 then
						sequence = 0
					elseif buf3 == 0x49 then
						sequence = 1
					end
				elseif buf2 == 0x26 then
					sequence = 2
					i = i + 3
				elseif buf2 == 0x24 then
					if buf3 == 0x40 or buf3 == 0x42 then
						sequence = 2
					elseif buf3 == 0x28 then
						sequence = 3
						i = i + 1
					end
				end
			else
				-- ASCII
				if sequence == 0 then
					unicode = buf1
				-- HALFWIDTH_KATAKANA
				elseif sequence == 1 then
					unicode = buf1 + 0xFF40
				-- KANJI
				elseif sequence == 2 then
					local code = ( bit32.lshift(buf1, 8) ) + buf:at(i)
					i = i + 1
					unicode  = tableJis[ code ] or unknown
				-- EXTENSION
				elseif sequence == 3 then
					local code = ( bit32.lshift(buf1, 8) ) + buf:at(i)
					i = i + 1
					unicode  = tableJisExt[ code ] or unknown
				end

				offset = setUnicodeBuffer( unicode, unicodeBuf, offset )
			end
		end
		return unicodeBuf:slice( 0, offset )
	end
})

-- JIS -> UTF8
_jconv.defineEncoding({
	name = 'JIStoUTF8',

	convert = function( buf )
		local tableJis    = tables[ 'JIS' ]
		local tableJisExt = tables[ 'JISEXT' ]
		local setUtf8Buf  = setUtf8Buffer

		local len      = buf:length()
		local utf8Buf  = Buffer.new( len * 2 )
		local offset   = 0
		local unicode
		local sequence = 0

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1

			-- ESC Sequence
			if buf1 == 0x1b then
				local buf2 = buf:at(i)
				i = i + 1
				local buf3 = buf:at(i)
				i = i + 1

				if buf2 == 0x28 then
					if buf3 == 0x42 or buf == 0xA1 then
						sequence = 0
					elseif buf3 == 0x49 then
						sequence = 1
					end
				elseif buf2 == 0x26 then
					sequence = 2
					i = i + 3
				elseif buf2 == 0x24 then
					if buf3 == 0x40 or buf3 == 0x42 then
						sequence = 2
					elseif buf3 == 0x28 then
						sequence = 3
						i = i + 1
					end
				end
			else
				-- ASCII
				if sequence == 0 then
					unicode = buf1
				-- HALFWIDTH_KATAKANA
				elseif sequence == 1 then
					unicode = buf1 + 0xFF40
				-- KANJI
				elseif sequence == 2 then
					local code = ( bit32.lshift(buf1, 8) ) + buf:at(i)
					i = i + 1
					unicode  = tableJis[ code ] or unknown
				-- EXTENSION
				elseif sequence == 3 then
					local code = ( bit32.lshift(buf1, 8) ) + buf:at(i)
					i = i + 1
					unicode  = tableJisExt[ code ] or unknown
				end
				offset = setUtf8Buf( unicode, utf8Buf, offset )
			end
		end
		return utf8Buf:slice( 0, offset )
	end
})

-- JIS -> SJIS
_jconv.defineEncoding({
	name = 'JIStoSJIS',

	convert = function( buf )
		local tableSjis    = tables[ 'SJIS' ]
		local tableSjisInv = tables[ 'SJISInverted' ]
		local unknownSjis  = tableSjisInv[ unknown ]

		local len      = buf:length()
		local sjisBuf  = Buffer.new( len * 2 )
		local offset   = 0
		local sequence = 0

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1

			-- ESC Sequence
			if buf1 == 0x1b then
				local buf2 = buf:at(i)
				i = i + 1
				local buf3 = buf:at(i)
				i = i + 1
				if buf2 == 0x28 then
					if buf3 == 0x42 or buf == 0xA1 then
						sequence = 0
					elseif buf3 == 0x49 then
						sequence = 1
					end
				elseif buf2 == 0x26 then
					sequence = 2
					i = i + 3
				elseif buf2 == 0x24 then
					if buf3 == 0x40 or buf3 == 0x42 then
						sequence = 2
					elseif buf3 == 0x28 then
						sequence = 3
						i = i + 1
					end
				end
			else
				-- ASCII
				if sequence == 0 then
					sjisBuf:writeAt(offset, buf1)
					offset = offset + 1
				-- HALFWIDTH_KATAKANA
				elseif sequence == 1 then
					sjisBuf:writeAt(offset, buf1 + 0x80)
					offset = offset + 1
				-- KANJI
				elseif sequence == 2 then
					local buf2 = buf:at(i)
					i = i + 1
					if bit32.band(buf1, 0x01) ~= 0 then
						buf1 = bit32.arshift(buf1, 1)
						if buf1 < 0x2F then
							buf1 = buf1 + 0x71
						else
							buf1 = buf1 - 0x4F
						end
						if buf2 > 0x5F then
							buf2 = buf2 + 0x20
						else
							buf2 = buf2 + 0x1F
						end
					else
						buf1 = bit32.arshift(buf1, 1)
						if buf1 <= 0x2F then
							buf1 = buf1 + 0x70
						else
							buf1 = buf1 - 0x50
						end
						buf2 = buf2 + 0x7E
					end
					-- NEC SELECT IBM EXTENSION -> IBM EXTENSION.
					local sjis = ( bit32.lshift(bit32.band(buf1, 0xFF), 8) ) + buf2
					if 0xED40 <= sjis and sjis <= 0xEEFC then
						local unicode   = tableSjis[ sjis ]
						local sjisFixed = tableSjisInv[ unicode ] or unknownSjis

						buf1 = bit32.arshift(sjisFixed, 8)
						buf2 = bit32.band(sjisFixed, 0xFF)
					end
					sjisBuf:writeAt(offset, buf1)
					offset = offset + 1
					sjisBuf:writeAt(offset, buf2)
					offset = offset + 1
				-- EXTENSION
				elseif sequence == 3 then
					sjisBuf:writeAt(offset, bit32.arshift(unknownSjis, 8))
					offset = offset + 1
					sjisBuf:writeAt(offset, bit32.band(unknownSjis, 0xFF))
					offset = offset + 1
					i = i + 1
				end
			end
		end
		return sjisBuf:slice( 0, offset )
	end
})

-- JIS -> EUCJP
_jconv.defineEncoding({
	name = 'JIStoEUCJP',

	convert = function( buf )
		local len      = buf:length()
		local eucBuf   = Buffer.new( len * 2 )
		local offset   = 0
		local sequence = 0

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1

			-- ESC Sequence
			if buf1 == 0x1b then
				local buf2 = buf:at(i)
				i = i + 1
				local buf3 = buf:at(i)
				i = i + 1
				if buf2 == 0x28 then
					if buf3 == 0x42 or buf == 0xA1 then
						sequence = 0
					elseif buf3 == 0x49 then
						sequence = 1
					end
				elseif buf2 == 0x26 then
					sequence = 2
					i = i + 3
				elseif buf2 == 0x24 then
					if buf3 == 0x40 or buf3 == 0x42 then
						sequence = 2
					elseif buf3 == 0x28 then
						sequence = 3
						i = i + 1
					end
				end
			else
				-- ASCII
				if sequence == 0 then
					eucBuf:writeAt(offset, buf1)
					offset = offset + 1
				-- HALFWIDTH_KATAKANA
				elseif sequence == 1 then
					eucBuf:writeAt(offset, 0x8E)
					offset = offset + 1
					eucBuf:writeAt(offset, buf1 + 0x80)
					offset = offset + 1
				-- KANJI
				elseif sequence == 2 then
					eucBuf:writeAt(offset, buf1 + 0x80)
					offset = offset + 1
					eucBuf:writeAt(offset, buf:at(i) + 0x80)
					i = i + 1
					offset = offset + 1
				-- EXTENSION
				elseif sequence == 3 then
					eucBuf:writeAt(offset, 0x8F)
					offset = offset + 1
					eucBuf:writeAt(offset, buf1 + 0x80)
					offset = offset + 1
					eucBuf:writeAt(offset, buf:at(i) + 0x80)
					i = i + 1
					offset = offset + 1
				end
			end
		end
		return eucBuf:slice( 0, offset )
	end
})

-- EUCJP -> UCS2
_jconv.defineEncoding({
	name = 'EUCJPtoUCS2',

	convert = function( buf )
		local tableJis      = tables[ 'JIS' ]
		local tableJisExt   = tables[ 'JISEXT' ]
		local setUnicodeBuf = setUnicodeBuffer

		local len        = buf:length()
		local unicodeBuf = Buffer.new( len * 2 )
		local offset     = 0
		local unicode

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1

			-- ASCII
			if buf1 < 0x80 then
				unicode = buf1
			-- HALFWIDTH_KATAKANA
			elseif buf1 == 0x8E then
				unicode = buf:at(i) + 0xFEC0
				i = i + 1
			-- EXTENSION
			elseif buf1 == 0x8F then
				local jisbuf2 = buf:at(i) - 0x80
				i = i + 1
				local jisbuf3 = buf:at(i) - 0x80
				i = i + 1
				local jis = ( bit32.lshift(jisbuf2, 8) ) + jisbuf3
				unicode = tableJisExt[ jis ] or unknown
			-- KANJI
			else
				local jisbuf1 = buf1 - 0x80
				local jisbuf2 = buf:at(i) - 0x80
				i = i + 1
				local jis = ( bit32.lshift(jisbuf1, 8) ) + jisbuf2
				unicode = tableJis[ jis ] or unknown
			end
			offset = setUnicodeBuf( unicode, unicodeBuf, offset )
		end
		return unicodeBuf:slice( 0, offset )
	end
})

-- EUCJP -> UTF8
_jconv.defineEncoding({
	name = 'EUCJPtoUTF8',

	convert = function( buf )
		local tableJis    = tables[ 'JIS' ]
		local tableJisExt = tables[ 'JISEXT' ]
		local setUtf8Buf  = setUtf8Buffer

		local len     = buf:length()
		local utf8Buf = Buffer.new( len * 2 )
		local offset  = 0
		local unicode

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1

			-- ASCII
			if buf1 < 0x80 then
				unicode = buf1
			-- HALFWIDTH_KATAKANA
			elseif buf1 == 0x8E then
				unicode = buf:at(i) + 0xFEC0
				i = i + 1
			-- EXTENSION
			elseif buf1 == 0x8F then
				local jisbuf2 = buf:at(i) - 0x80
				i = i + 1
				local jisbuf3 = buf:at(i) - 0x80
				i = i + 1
				local jis = ( bit32.lshift(jisbuf2, 8) ) + jisbuf3
				unicode = tableJisExt[ jis ] or unknown
			-- KANJI
			else
				local jisbuf1 = buf1 - 0x80
				local jisbuf2 = buf:at(i) - 0x80
				i = i + 1
				local jis = ( bit32.lshift(jisbuf1, 8) ) + jisbuf2
				unicode = tableJis[ jis ] or unknown
			end
			offset = setUtf8Buf( unicode, utf8Buf, offset )
		end
		return utf8Buf:slice( 0, offset )
	end
})

-- EUCJP -> SJIS
_jconv.defineEncoding({
	name = 'EUCJPtoSJIS',

	convert = function( buf )
		local tableSjis    = tables[ 'SJIS' ]
		local tableSjisInv = tables[ 'SJISInverted' ]
		local unknownSjis  = tableSjisInv[ unknown ]

		local len     = buf:length()
		local sjisBuf = Buffer.new( len * 2 )
		local offset  = 0

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1

			-- ASCII
			if buf1 < 0x80 then
				sjisBuf:writeAt(offset, buf1)
				offset = offset + 1
			-- HALFWIDTH_KATAKANA
			elseif buf1 == 0x8E then
				sjisBuf:writeAt(offset, buf:at(i))
				i = i + 1
				offset = offset + 1
			-- EXTENSION
			elseif buf1 == 0x8F then
				sjisBuf:writeAt(offset, bit32.arshift(unknownSjis, 8))
				offset = offset + 1
				sjisBuf:writeAt(offset, bit32.band(unknownSjis, 0xFF))
				offset = offset + 1
				i = i + 2
			-- KANJI
			else
				local buf2 = buf:at(i)
				i = i + 1
				if bit32.band(buf1, 0x01) ~= 0 then
					buf1 = bit32.arshift(buf1, 1)
					if buf1 < 0x6F then
						buf1 = buf1 + 0x31
					else
						buf1 = buf1 + 0x71
					end
					if buf2 > 0xDF then
						buf2 = buf2 - 0x60
					else
						buf2 = buf2 - 0x61
					end
				else
					buf1 = bit32.arshift(buf1, 1)
					if buf1 <= 0x6F then
						buf1 = buf1 + 0x30
					else
						buf1 = buf1 + 0x70
					end
					buf2 = buf2 - 0x02
				end
				-- NEC SELECT IBM EXTENSION -> IBM EXTENSION.
				local sjis = ( bit32.lshift(bit32.band(buf1, 0xFF), 8) ) + buf2
				if 0xED40 <= sjis and sjis <= 0xEEFC then
					local unicode   = tableSjis[ sjis ]
					local sjisFixed = tableSjisInv[ unicode ] or unknownSjis

					buf1 = bit32.arshift(sjisFixed, 8)
					buf2 = bit32.band(sjisFixed, 0xFF)
				end
				sjisBuf:writeAt(offset, buf1)
				offset = offset + 1
				sjisBuf:writeAt(offset, buf2)
				offset = offset + 1
			end
		end
		return sjisBuf:slice( 0, offset )
	end
})

-- EUCJP -> JIS
_jconv.defineEncoding({
	name = 'EUCJPtoJIS',

	convert = function( buf )
		local len      = buf:length()
		local jisBuf   = Buffer.new( len * 3 + 4 )
		local offset   = 0
		local sequence = 0

		local i = 0
		while i < len do
			local buf1 = buf:at(i)
			i = i + 1

			-- ASCII
			if buf1 < 0x80 then
				if sequence ~= 0 then
					sequence = 0
					jisBuf:writeAt(offset, 0x1B)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x28)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x42)
					offset = offset + 1
				end
				jisBuf:writeAt(offset, buf1)
				offset = offset + 1
			-- HALFWIDTH_KATAKANA
			elseif buf1 == 0x8E then
				if sequence ~= 1 then
					sequence = 1
					jisBuf:writeAt(offset, 0x1B)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x28)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x49)
					offset = offset + 1
				end
				jisBuf:writeAt(offset, buf:at(i) - 0x80)
				i = i + 1
				offset = offset + 1
			-- EXTENSION
			elseif buf1 == 0x8F then
				if sequence ~= 3 then
					sequence = 3
					jisBuf:writeAt(offset, 0x1B)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x24)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x28)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x44)
					offset = offset + 1
				end
				jisBuf:writeAt(offset, buf:at(i) - 0x80)
				i = i + 1
				offset = offset + 1
				jisBuf:writeAt(offset, buf:at(i) - 0x80)
				i = i + 1
				offset = offset + 1
			-- KANJI
			else
				if sequence ~= 2 then
					sequence = 2
					jisBuf:writeAt(offset, 0x1B)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x24)
					offset = offset + 1
					jisBuf:writeAt(offset, 0x42)
					offset = offset + 1
				end
				jisBuf:writeAt(offset, buf1 - 0x80)
				offset = offset + 1
				jisBuf:writeAt(offset, buf:at(i) - 0x80)
				i = i + 1
				offset = offset + 1
			end
		end

		-- Add ASCII ESC
		if sequence ~= 0 then
			sequence = 0
			jisBuf:writeAt(offset, 0x1B)
			offset = offset + 1
			jisBuf:writeAt(offset, 0x28)
			offset = offset + 1
			jisBuf:writeAt(offset, 0x42)
			offset = offset + 1
		end
		return jisBuf:slice( 0, offset )
	end
})


return _jconv
