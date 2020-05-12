-----------------------------------------------------------------------------
-- HTK:
-- A toolkit made with htmltoolkit.
-- HTK offers a collection of constructors very similar to HTML elements,
-- but with "Lua style".
-----------------------------------------------------------------------------

local I = {}
local E = {}
HTK = E

-----------------------------------------------------------------------------
-- VIRTUAL
-- Constructors that encapsulate HTML elements giving a "Lua style":
--	FRAME
--	MULTILINE
-----------------------------------------------------------------------------
function E.FRAME (param)
   local t = {}
   if param.border then
      t.border = param.border
      param.border = nil
   else
      t.border = 1
   end
   t[1] = TR { TD (param) }
   return TABLE (t)
end

function E.MULTILINE (param)
   if param.value then
      param[1] = param.value
      param.value = nil
   end
   return TEXTAREA (param)
end

E.TEXTAREA = E.MULTILINE

-----------------------------------------------------------------------------
-- INPUT
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
function E.BUTTON (param)
   param.type = "button"
   return INPUT (param)
end

function E.FILE (param)
   param.type = "file"
   return INPUT (param)
end

function E.HIDDEN (param)
   param.type = "hidden"
   return INPUT (param)
end

function E.PASSWORD (param)
   param.type = "password"
   return INPUT (param)
end

function E.RADIO_BUTTON (param)
   param.type = "radio"
   return INPUT (param)
end

function E.RESET (param)
   param.type = "reset"
   return INPUT (param)
end

function E.SUBMIT (param)
   param.type = "submit"
   return INPUT (param)
end

function E.TEXT (param)
   param.type = "text"
   return INPUT (param)
end

function E.TOGGLE (param)
   param.type = "checkbox"
   return INPUT (param)
end

-----------------------------------------------------------------------------
-- CONTAINERS
-- Constructors that creates some abstractions or encapsulation:
--	RADIO (many RADIO_BUTTON's == INPUT with type='radio')
--	TOGGLE_LIST (many TOGGLE's == INPUT with type='checkbox')
--	SELECT (manu OPTION's enclosed in a SELECT element)
-----------------------------------------------------------------------------
--function HTK._button_list (param, element)
--   local i = 1
--   while param[i] do
--      if type(param[i]) == "table" then
--         if not param[i].name then
--            param[i].name = param.name
--         end
--         if not param[i].value then
--            param[i].value = param[i][1]
--         end
--         param[i] = BOX {
--		HTK[element] (param[i]),
--		BR {},
--         }
--      else
--         param[i] = BOX {
--		HTK[element] { name = param.name, value = param[i], },
--		param[i],
--		BR {},
--         }
--      end
--      i = i+1
--   end
--   param.separator = '\n'
--   return BOX (param)
--end
function I._button_list (param, element)
   local item_separator = param.item_separator or BR{}
   local list = param.options
   local i = 1
   while list[i] do
      if type(list[i]) == "table" then
         if not list[i].name then
            list[i].name = param.name
         end
         if not list[i].value then
            list[i].value = list[i][1]
         end
         if param.value == list[i].value then
            list[i].checked = 1
         end
         param[i] = BOX {
		%E[element] (list[i]),
		item_separator,
         }
      else
         param[i] = BOX {
		%E[element] {
			name = param.name,
			value = list[i],
			checked = list[i]==param.value,
		},
		list[i],
		item_separator,
         }
      end
      i = i+1
   end
   param.separator = '\n'
   return BOX (param)
end

function E.RADIO (param)
   return %I._button_list (param, "RADIO_BUTTON")
end

function E.TOGGLE_LIST (param)
   return %I._button_list (param, "TOGGLE")
end

--function HTK.SELECT (param)
--   local i = 1
--   while param[i] do
--      if type(param[i]) == "table" then
--         param[i] = OPTION { param[i][1]; value = param[i].value,
--		selected = param[i].selected }
--      else
--         param[i] = OPTION { param[i]; selected = param.selected==i }
--      end
--      i = i+1
--   end
--   param.separator = '\n'
--   param.selected = nil
--   return SELECT (param)
--end

function E.SELECT (param)
   local list = param.options
   local i = 1
   while list[i] do
      if type(list[i]) == "table" then
         param[i] = OPTION {
		list[i][1];
		value = list[i].value,
		selected = list[i].selected or
			(list.selected == i) or
			(param.value == list[i].value) or
			(param.value == list[i][1]),
         }
      else
         param[i] = OPTION {
		list[i];
		selected = list.selected == i or (param.value == list[i]),
         }
      end
      i = i+1
   end
   param.options = nil
   param.value = nil
   param.separator = '\n'
   param.selected = nil
   return SELECT (param)
end

-----------------------------------------------------------------------------
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

function E.COMPOUND (param)
   local i = 1
   while param[i] do
      if type(param[i]) == "table" then
         -- Define attribute name.
         if not param[i].name then
            param[i].name = param.name.."_"..i
         end

         -- Create elements.
         local t = param[i].type
         param[i].type = nil
         param[i] = %E[t] (param[i])
      end
      i = i+1
   end
   return BOX (param)
end

function E.DATE (param)
   param[1] = { type = "TEXT", size = 2, maxlength = 2, }
   param[2] = { type = "SELECT", options = { "janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro" }, }
   param[3] = { type = "TEXT", size = 4, maxlength = 4, }
   if param.value then
      gsub (param.value, "^(%d+)/([^/]+)/(%d+)$", function (d, m, a)
		%param[1].value = d
		%param[2].options.selected = tonumber(m)
		%param[3].value = a
      end)
      gsub (param.value, "^(%d+)%-(%d+)%-(%d+)$", function (a, m, d)
		%param[1].value = d
		%param[2].options.selected = tonumber(m)
		%param[3].value = a
      end)
   end
   return %E.COMPOUND (param)
end

-----------------------------------------------------------------------------
-- TABLE Cells
-- Constructors that "give" a face and size attributes, to set fonts.
-----------------------------------------------------------------------------
function I._cell (param)
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
   param[1] = FONT (content)
   param.face = nil
   param.size = nil
   return param
end

function E.TH (param)
   return TH (%I._cell(param))
end

function E.TD (param)
   return TD (%I._cell(param))
end

-----------------------------------------------------------------------------
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
-----------------------------------------------------------------------------
function I._field (param, element)
   local label = param.label
   local font_size = param.font_size
   local label_align = param.label_align
   local align = param.align
   param.label = nil
   param.font_size = nil
   param.label_align = nil
   param.align = nil
   return TR {
	%E.TD { label; face = param.face, size = font_size, align = label_align, },
	%E.TD { %E[element] (param); face = param.face, size = font_size, align = align, },
	; separator = '\n',
   }
end

function E.DATE_FIELD (param)
   return %I._field (param, "DATE")
end

function E.FILE_FIELD (param)
   return %I._field (param, "FILE")
end

function E.PASSWORD_FIELD (param)
   return %I._field (param, "PASSWORD")
end

function E.RADIO_FIELD (param)
   return %I._field (param, "RADIO")
end

function E.SELECT_FIELD (param)
   return %I._field (param, "SELECT")
end

function E.TEXT_FIELD (param)
   return %I._field (param, "TEXT")
end

function E.TEXTAREA_FIELD (param)
   return %I._field (param, "MULTILINE")
end

E.MULTILINE_FIELD = E.TEXTAREA_FIELD

function E.TOGGLE_FIELD (param)
   return %I._field (param, "TOGGLE")
end
