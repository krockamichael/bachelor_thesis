-----------------------------------------------------------------------------
-- A toolkit for constructing HTML pages.
-- @title HTK 3.3.
-- HTK offers a collection of constructors very similar to HTML elements,
-- but with "Lua style".
-- This version does not require HTMLToolkit.
-- It does require Lua 5.
-- @release $Id: htk-3.3.1.lua,v 1.1 2013/02/08 01:41:45 tomas Exp $
-----------------------------------------------------------------------------

-- Internal structure.
-- The field [[valid_tags]] stores the names of the HTML elements that
-- can be built on-demand.
-- All element constructors are named in capital letters.

local valid_tags = {
	A = 1, ABBR = 1, ABBREV = 1, ACRONYM = 1, ADDRESS = 1, APP = 1,
	APPLET = 1, AREA = 2, AU = 1,
	B = 1, BANNER = 1, BASE = 2, BASEFONT = 2, BDO = 1, BGSOUND = 1,
	BIG = 1, BLINK = 1, BLOCKQUOTE = 1, BODY = 1, BQ = 1, BR = 2,
	BUTTON = 1,
	CAPTION = 1, CENTER = 1, CITE = 1, CODE = 1, COL = 2, COLGROUP = 1,
	CREDIT = 1,
	DD = 1, DEL = 1, DFN = 1, DIR = 1, DIV = 1, DL = 1, DT = 1,
	EM = 1, EMBED = 1,
	FIELDSET = 1, FIG = 1, FN = 1, FONT = 1, FORM = 1, FRAME = 2,
	FRAMESET = 1,
	H1 = 1, H2 = 1, H3 = 1, H4 = 1, H5 = 1, H6 = 1, HEAD = 1, HR = 2,
	HTML = 1,
	I = 1, IFRAME = 1, IMG = 2, INPUT = 2, INS = 1, ISINDEX = 2,
	KBD = 1,
	LABEL = 1, LANG = 1, LEGEND = 1, LH = 1, LI = 1, LINK = 2, LISTING = 1,
	MAP = 1, MARQUEE = 1, MENU = 1, META = 2,
	NEXTID = 1, NOBR = 1, NOEMBED = 1, NOFRAMES = 1, NOSCRIPT = 1, NOTE = 1,
	OBJECT = 1, OL = 1, OPTGROUP = 1, OPTION = 1, OVERLAY = 1,
	P = 2, PARAM = 2, PERSON = 1, PLAINTEXT = 1, PRE = 1,
	Q = 1,
	S = 1, SAMP = 1, SCRIPT = 1, SELECT = 1, SMALL = 1, SPAN = 1,
	STRIKE = 1, STRONG = 1, STYLE = 1, SUB = 1, SUP = 1,
	TAB = 1, TABLE = 1, TBODY = 1, TD = 1, TEXTAREA = 1, TFOOT = 1, TH = 1,
	THEAD = 1, TITLE = 1, TR = 1, TT = 1,
	U = 1, UL = 1,
	VAR = 1,
	WBR = 1,
	XMP = 1,
}

local getmetatable, pairs, setmetatable, tonumber, type = getmetatable, pairs, setmetatable, tonumber, type
local format, match, strfind, strlen = string.format, string.match, string.find, string.len
local tinsert, tremove = table.insert, table.remove


local _M = {
	_COPYRIGHT = "Copyright (C) 2010-2013 PUC-Rio",
	_DESCRIPTION = "HTK is a library of Lua constructors that create HTML elements.",
	_VERSION = "HTK 3.3.1",
}

_M.class_defaults = {}

-- stack of strings.
-- from ltn009 (by Roberto Ierusalimschy)
local function newStack ()
	return { n = 0 }
end

local function addString (stack, s)
	tinsert (stack, s)
	for i = #stack-1, 1, -1 do
		if strlen(stack[i]) > strlen (stack[i+1]) then
			break
		end
		stack[i] = stack[i]..tremove(stack)
	end
end

local function toString (stack)
	for i = #stack-1, 1, -1 do
		stack[i] = stack[i]..tremove(stack)
	end
	return stack[1]
end

-- Build an HTML element constructor.
-- The resulting function -- the constructor -- will receive a table
-- representing the HTML element.
-- This table can hold the attributes of the element and its content, i.e.,
-- other elements that will be "inside" it.
-- All HTML elements have a special attribute called [[separator]];
-- it can be used to store a string that will be "printed" between
-- every content-element.
-- @param field String with the name of the tag.
-- @return Function that makes an HTML element represented by a table.

local function build_constructor (field)
	return function (obj)
		local separator = obj.separator or ''
		local contain = {}
		local s = newStack ()
		addString (s, '<'..field)
		for i, v in pairs (obj) do
			if type(i) == "number" then
				contain[i] = v
			elseif i ~= "separator" then
				if v == true then
					addString (s, format (' %s', i ))
				else
					local tt = type(v)
					if tt == "string" or tt == "number" then
						addString (s, format (' %s="%s"', i, v))
					end
				end
			end
		end
		if not obj.class and _M.class_defaults[field] then
			addString (s, format (' class="%s"', _M.class_defaults[field]))
		end
		addString (s, '>'..separator)
		local n = #contain
		for i = 1, n do
			addString (s, contain[i])
			addString (s, separator)
		end
		if (n > 0) or (valid_tags[field] == 1) then
			addString (s, '</'..field..'>')
		end
		return toString (s)
	end
end

-- Implements the "on-demand constructor builder" mechanism.
-- It works like the inheritance mechanism but if the index is a
-- valid tag then the constructor builder is called and the resulting
-- function is returned.
-- @param obj Table representing the object.
-- @param field Index of the table.
-- @return [[ obj[field] ]].

setmetatable (_M, {
	__index = function (obj, field)
		if valid_tags[field] then
			-- On-demand constructor builder
			local c = build_constructor (field)
			_M[field] = c
			return c
		elseif old_index then
			return old_index (obj, field)
		end
	end,
})


-----------------------------------------------------------------------------
-- Constructors.
-----------------------------------------------------------------------------

-- Primitive [[TEXTAREA]] constructor.
-- These constructors will be used by the efective ones.
local _TEXTAREA = build_constructor ("TEXTAREA")

local _TD = build_constructor ("TD")

local _TH = build_constructor ("TH")

local _SELECT = build_constructor ("SELECT")



-- DEPRECATED Constructors.
-- Constructors that encapsulate deprecated HTML elements generating
-- the equivalent efect with non-deprecated elements.

-----------------------------------------------------------------------------
-- Construct an [[OBJECT]] element compatible to an [[APPLET]].
-- @param obj Table with object description.
-- @return String with HTML representation of the object.

function _M.APPLET (obj)
	obj.codetype = "application/java"
	obj.classid = "java:"..(obj.code or obj.object)
	obj.code = nil
	obj.object = nil
	return _M.OBJECT (obj)
end

-----------------------------------------------------------------------------
-- Construct a [[DIV]] element compatible to a [[CENTER]].
-- @param obj Table with object description.
-- @return String with HTML representation of the object.

function _M.CENTER (obj)
	obj.align = "center"
	return _M.DIV (obj)
end

-- VIRTUAL Constructors.
-- Constructors that encapsulate HTML elements giving a "Lua style":
--	BOX
--	MULTILINE

-----------------------------------------------------------------------------
-- Group together other elements.
-- @param obj Table with object description.
-- @return String with HTML representation of the object.

function _M.BOX (obj)
	local separator = obj.separator or ''
	local s = ""
	for i = 1, #obj do
		s = format ('%s%s', s, obj[i], separator)
	end
	return s
end

-----------------------------------------------------------------------------
-- Construct a [[TEXTAREA]] HTML element.
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.MULTILINE (param)
	if param.value then
		param[1] = param.value
		param.value = nil
	end
	return _TEXTAREA (param)
end

_M.TEXTAREA = _M.MULTILINE

-- INPUT Constructors.
-- Constructors that encapsulate the INPUT element:
--	BUTTON
--	FILE
--	HIDDEN
--	PASSWORD
--	RADIO_BUTTON == INPUT with type='radio'
--	RESET
--	SUBMIT
--	TEXT
--	TOGGLE == INPUT with type='checkbox'

-----------------------------------------------------------------------------
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.BUTTON (param)
	param.type = "button"
	return _M.INPUT (param)
end

-----------------------------------------------------------------------------
-- Construct an [[INPUT]] element with type attribute set to [[file]].
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.FILE (param)
	param.type = "file"
	return _M.INPUT (param)
end

-----------------------------------------------------------------------------
-- Construct an [[INPUT]] element with type attribute set to [[hidden]].
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.HIDDEN (param)
	param.type = "hidden"
	if type(param.value) ~= "table" then
		return _M.INPUT (param)
	else
		local val = param.value
		local box = {}
		for i, v in pairs (val) do
			param.value = v
			tinsert (box, _M.INPUT (param))
		end
		return _M.BOX (box)
	end
end

-----------------------------------------------------------------------------
-- Construct an [[INPUT]] element with type attribute set to [[password]].
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.PASSWORD (param)
	param.type = "password"
	return _M.INPUT (param)
end

-----------------------------------------------------------------------------
-- Construct an [[INPUT]] element with type attribute set to [[radio]].
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.RADIO_BUTTON (param)
	param.type = "radio"
	return _M.INPUT (param)
end

-----------------------------------------------------------------------------
-- Construct an [[INPUT]] element with type attribute set to [[reset]].
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.RESET (param)
	param.type = "reset"
	return _M.INPUT (param)
end

-----------------------------------------------------------------------------
-- Construct an [[INPUT]] element with type attribute set to [[submit]].
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.SUBMIT (param)
	param.type = "submit"
	return _M.INPUT (param)
end

-----------------------------------------------------------------------------
-- Construct an [[INPUT]] element with type attribute set to [[text]].
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.TEXT (param)
	param.type = "text"
	return _M.INPUT (param)
end

-----------------------------------------------------------------------------
-- Construct an [[INPUT]] element with type attribute set to [[checkbox]].
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.TOGGLE (param)
	param.type = "checkbox"
	return _M.INPUT (param)
end



-- CONTAINERS
-- Constructors that creates some abstractions or encapsulation:

local function findnum (str, num)
	num = tostring(num)
	local ok = false
	str:gsub ("(%d+)", function (n) if n==num then ok = true end end)
	return ok
end

-- @param param Table with object description.
-- @param element String with the name of the HTML element.
-- @return String with the HTML representation of the element.

local function button_list (param, element)
	local item_separator = param.item_separator or _M.BR{}.."\n"
	local list = param.options
	for i = 1, #list do
		local tli = type(list[i])
		if tli == "table" then
			if not list[i].name then
				list[i].name = param.name
			end
			if not list[i].value then
				list[i].value = list[i][1]
			end
			--if param.value and strfind (param.value..',',  list[i].value, 1, 1) then
			if param.value and findnum (param.value, list[i].value) then
				list[i].checked = true
			end
			param[i] = _M.BOX {
				_M[element] (list[i]),
				item_separator,
			}
		elseif tli == "function" then	-- OTHER function!
			param[i] = _M.BOX {
				_M[element] (list[i] (param)),
				item_separator,
			}
		else
			param[i] = _M.BOX {
				_M[element] {
					name = param.name,
					value = list[i],
					checked = list[i]==param.value,
				},
				list[i],
				item_separator,
			}
		end
	end
	param.separator = '\n'
	return _M.BOX (param)
end

-----------------------------------------------------------------------------
-- Construct a list of [[RADIO_BUTTON]]s.
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.RADIO (param)
	return button_list (param, "RADIO_BUTTON")
end

-----------------------------------------------------------------------------
-- Construct a list of [[TOGGLE]]s (checkbox buttons).
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.TOGGLE_LIST (param)
	return button_list (param, "TOGGLE")
end

--
local function equal (str, sub)
	return str == sub
end

--
local function check_selected (param, i)
	local list = param.options or {}
	local is_table = type(list[i]) == "table"
	local find
	if param.multiple then
		find = findnum
	else
		find = equal
	end
	if (is_table and list[i].selected) or
		(type(list.selected)=="string" and find (list.selected, i)) or
		(param.value and is_table and (
			(find (param.value, list[i].value)) or
			(find (param.value, list[i][1]))
		)) or
		param.value == i or param.value == list[i] then
		return true
	else
		return nil
	end
end

-----------------------------------------------------------------------------
-- Construct a selection list.
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.SELECT (param)
	local list = param.options
	for i = 1, #list do
		local selected = check_selected (param, i)
		if type(list[i]) == "table" then
			param[i] = _M.OPTION {
				list[i][1],
				value = list[i].value,
				selected = check_selected (param, i),
				disabled = list[i].disabled,
			}
		else
			param[i] = _M.OPTION {
				list[i],
				selected = check_selected (param, i),
			}
		end
	end
	param.options = nil
	param.value = nil
	param.separator = '\n'
	param.selected = nil
	return _SELECT (param)
end



-- COMPOUND Elements
-- Constructors that join together some elements to create a more powerfull
-- abstraction:
--	-- RADIO + TEXT => ( ) 1
--			   ( ) 2
--			   ( ) Mais de 2 _____________________________
--	-- TEXT + SELECT + SELECT => [ dia ] / [ janeiro ]   / [ 2000 ]
--                                             [ fevereiro ]   [ 2001 ]
--                                             ...             ...

-----------------------------------------------------------------------------
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.COMPOUND (param)
	for i = 1, #param do
		if type(param[i]) == "table" then
			-- Define attribute name.
			if not param[i].name then
				param[i].name = param.name.."_"..i
			end

			-- Create elements.
			local t = param[i].type
			param[i].type = nil
			param[i] = _M[t] (param[i])
		end
	end
	return _M.BOX (param)
end

-----------------------------------------------------------------------------
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.DATE (param)
	param[1] = { type = "TEXT", size = 2, maxlength = 2, }
	param[2] = { type = "SELECT", options = { "janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro" }, }
	param[3] = { type = "TEXT", size = 4, maxlength = 4, }
	if param.value then
		local d, s1, m, s2, y = match (s, "^(%d+)([/-])(%d+)([/-])(%d+)$")
		assert (s1 == s2)
		if s1 == '-' then
			d, y = y, d
		end
		param[1].value = d
		param[2].value = m
		param[3].value = y
--[[
		gsub (param.value, "^(%d+)/([^/]+)/(%d+)$", function (d, m, a)
			param[1].value = d
			param[2].value = tonumber(m)
			param[3].value = a
		end)
		gsub (param.value, "^(%d+)%-(%d+)%-(%d+)$", function (a, m, d)
			param[1].value = d
			param[2].value = tonumber(m)
			param[3].value = a
		end)
--]]
	end
	return _M.COMPOUND (param)
end

-----------------------------------------------------------------------------
function _M.RADIO_DATE (param)
end


-- TABLE Cells
-- Constructors that "give" a face and size attributes, to set fonts.

-- Process the special fields [[face]], [[size]] and [[color]] that
-- will be "passed" to a [[FONT]] element automatically created
-- inside the original object.
-- @param param Table with object description.
-- @return Table with object description modified.

local function table_cell (param)
	if param.face or param.size or param.color then
		local content = { separator='\n',
			face = param.face,
			size = param.size,
			color = param.color,
		}
		local i = 1
		while param[i] do
			content[i] = param[i]
			param[i] = nil
			i = i+1
		end
		param[1] = _M.FONT (content)
		param.face = nil
		param.size = nil
	end
	return param
end

-----------------------------------------------------------------------------
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.TH (param)
	return _TH (table_cell(param))
end

-----------------------------------------------------------------------------
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.TD (param)
	return _TD (table_cell(param))
end

-- TABLE Rows
-- Constructors that creates "fields" as table rows with two cells, the
-- left one with a label and the right one with an input element.
--	DATE_FIELD
--	MULTILINE_FIELD
--	PASSWORD_FIELD
--	RADIO_FIELD
--	SELECT_FIELD
--	TEXT_FIELD
--	TEXTAREA_FIELD
--	TOGGLE_FIELD
-- @param param Table with object description.
-- @param element String with element name.
-- @return String with HTML representation of element.

local function input_field (param, element)
	local label = param.label
	local font_size = param.font_size
	local label_align = param.label_align
	local class_label = param.class_label
	local align = param.align
	param.label = nil
	param.font_size = nil
	param.label_align = nil
	param.class_label = nil
	param.align = nil
	return _M.TR {
		_M.TD {
			label,
			class = class_label,
			face = param.face,
			size = font_size,
			align = label_align,
			separator = '\n',
		},
		_M.TD {
			_M[element] (param),
			face = param.face,
			size = font_size,
			align = align,
			separator = '\n',
		},
		separator = '\n',
	}
end

-----------------------------------------------------------------------------
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.DATE_FIELD (param)
	return input_field (param, "DATE")
end

-----------------------------------------------------------------------------
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.FILE_FIELD (param)
	return input_field (param, "FILE")
end

-----------------------------------------------------------------------------
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.PASSWORD_FIELD (param)
	return input_field (param, "PASSWORD")
end

-----------------------------------------------------------------------------
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.RADIO_FIELD (param)
	return input_field (param, "RADIO")
end

-----------------------------------------------------------------------------
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.SELECT_FIELD (param)
	return input_field (param, "SELECT")
end

-----------------------------------------------------------------------------
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.TEXT_FIELD (param)
	return input_field (param, "TEXT")
end

-----------------------------------------------------------------------------
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.TEXTAREA_FIELD (param)
	return input_field (param, "MULTILINE")
end

_M.MULTILINE_FIELD = _M.TEXTAREA_FIELD

-----------------------------------------------------------------------------
-- @param param Table with object description.
-- @return String with HTML representation of the object.

function _M.TOGGLE_FIELD (param)
	return input_field (param, "TOGGLE")
end

-- Check if the object value is identical to the value of any option.
-- @param obj Table with object description.
-- @return True or false.

local function checked (obj)
	for i, opt in pairs (obj.options) do
		if (type(opt) == "string" and opt == obj.value) or
			(type(opt) == "table" and opt.value == obj.value) then
			return i
		end
	end
	return nil
end

-- Clones a table.
-- Do not clone elements.
-- @param tab Table to clone.
-- @return Table cloned.

local function clone (tab)
	local new = {}
	for i, v in pairs (tab) do
		new[i] = v
	end
	return new
end

-----------------------------------------------------------------------------
-- Permits the inclusion of another element "as" a radio button.
-- For instance, one can define a radio with an option called "other"
-- followed by a text input.
-- This function only works because the RADIO constructor also expects
-- a function as an option.
-- @param param Table with object description.
-- @return Function that will create the option.

function _M.OTHER (param)
	return function (obj)
		-- Clone param table to reuse HTML attributes
		local p = clone (param)
		p[1] = nil
		p.type = nil
		p.name = obj.name.."__other_"
		p.value = (not checked (obj)) and obj.value
		return {
			_M.BOX {
				param[1],
				param.type (p),
			},
			name = obj.name,
			value = param.value,
			checked = (not checked (obj)) and obj.value,
		}
	end
end

return _M
