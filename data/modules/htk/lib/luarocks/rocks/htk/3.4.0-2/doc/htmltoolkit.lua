-----------------------------------------------------------------------------
-- This file implements a toolkit for the design of HTML pages. The mainly
-- concern is to create a compact and homogeneous way where HTML tags can 
-- be built, using the power of the lua language.


-----------------------------------------------------------------------------
-- Implements simple inheritance.
-- @param object Table representing the object.
-- @param field Index of the table.
-- @return [[ object[field] ]].

function Inherit (object,field)
  if field == "parent" then
    return nil
  end
  local p = rawgettable (object, "parent")
  if type(p) == 'table' then
    return p[field]
  else
    return nil
  end
end

settagmethod (tag({}), "index", Inherit)

-----------------------------------------------------------------------------
-- Splits a string according to a delimiter given.
-- @param str The string.
-- @param delim A string with the delimiter.
-- @return An array with the splitted strings and the number of them.

function strsplit( str, delim )
  local pos = 1
  local oldpos = 1
  local array = {}
  local i = 1

  pos = strfind( str, delim, oldpos, 1 )
  if pos then
    while pos do
      array[i] = strsub( str, oldpos, pos-1 )
      oldpos = pos + strlen( delim )
      i = i + 1
      pos = strfind( str, delim, oldpos, 1 )

      if pos == nil then
        array[i] = strsub( str, oldpos )
      end
    end
  else
    array[i] = str
  end

  return array,i
end

-----------------------------------------------------------------------------

-- Main context 

HtmlTag = {}


-----------------------------------------------------------------------------
-- Put the calling object on the hierarchy.

function HtmlTag:DeclareTag (o) 
  o.parent = self 
  return o 
end


-----------------------------------------------------------------------------
-- Move the objects indexed in the tag element with 
-- numbers to the [[contain]] field.

function HtmlTag:SetContainer()
   if not self[1] then
      return
   end
   self.contain = {}
   local i = 1
   while self[i] do
      self.contain[i] = self[i]
      self[i] = nil
      i = i+1
   end
end


-----------------------------------------------------------------------------
-- Perform the checking of the fields of the element
-- newly created. The functions to be applied on the field and the
-- fields to be checked are specified on the [[fields]] field of
-- its parent Descriptor.

function HtmlTag:SetFields()
  local attrib, f = next ( self.parent.fields, nil )

  while attrib do
    -- if the field has string type, call its check function
    -- f[1] is the check function and f[2] its optional parameters
    if type ( attrib ) == 'string' then
      self [ attrib ] = f[1] ( self, attrib , f[2] ) -- f[1] is a method
    end

    attrib, f = next( self.parent.fields, attrib )
  end
end


-----------------------------------------------------------------------------
-- Called by every tag's constructor and responsible for applying the
-- methods [[SetContainer]] and [[SetFields]].

function HtmlTag:BuildElement(t)
  t.parent = self
  t:SetContainer()
  t:SetFields()
  return t
end


-----------------------------------------------------------------------------
-- Pseudo-element to mark parts of the elements.

HtmlTag.Mark = function () end

-----------------------------------------------------------------------------
-- Adjust the given function and marks to work with [[toStream]].
-- @param func A function that will make the output for the element
-- (typically [[write]] or '[[return]]').
-- @param begin_mark The number of the first mark of the output (optional).
-- @param end_mark The number of the last mark of the output (optional).
-- @return The result of the call to [[toStream]].
-- @see HtmlTag.Print, HtmlTag.toString.

function HtmlTag:apply_between_marks (func, begin_mark, end_mark)
   HtmlTag.mark_counter = 0
   if not begin_mark then
      begin_mark = 0
   end
   return self:toStream (function (x)
	if HtmlTag.mark_counter >= %begin_mark and
		(not %end_mark or HtmlTag.mark_counter < %end_mark) then
	   local r = %func (x)
	   if type (r) == "string" then
	      return r
	   end
	end
	return ""
   end)
end


-----------------------------------------------------------------------------
-- Prints the element (and its child elements) on the HTML format.
-- The output can be made for a part of the element, according to some
-- marks.  These parts must be marked with the pseudo-element
-- [[HtmlTag.Mark]].
-- @param begin_mark The number of the first mark of the output (optional).
-- @param end_mark The number of the last mark of the output (optional).
-- @see HtmlTag.toString.

function HtmlTag:Print (begin_mark, end_mark)
   self:apply_between_marks (write, begin_mark, end_mark)
end


-----------------------------------------------------------------------------
-- Produces a string with the HTML format of the element.
-- The output can be made for a part of the element, according to some
-- marks.  These parts must be marked with the pseudo-element
-- [[HtmlTag.Mark]].
-- @param begin_mark The number of the first mark of the output (optional).
-- @param end_mark The number of the last mark of the output (optional).
-- @return A string with the "printed" element.
-- @see HtmlTag.Print.

function HtmlTag:toString (begin_mark, end_mark)
   return self:apply_between_marks (function (x) return x end, begin_mark,
	end_mark)
end


-----------------------------------------------------------------------------
-- Traverses the element to make a stream of it.
-- @param func An output function (typically [[write]] or '[[return]]').
-- @return The concatenation of all return values of the output function.

function HtmlTag:toStream (func)
  local result = ""

  -- first print the attributes of the element itself
  if self.tag ~= '' then
    local attrib, value = next ( self , nil )
    result = result..func ('<'..self.tag)
    while attrib do
      if type (attrib) == 'string'
		and (type (value) == 'string' or type (value) == 'number')
		and attrib ~= 'parent'
		and attrib ~= 'contain'
		and attrib ~= 'separator' then
        result = result..func (' '..attrib..'=')
        if type (self.parent.fields[attrib]) == 'table' then
          result = result..func (tostring(value))
        else
          result = result..func ('"'..value..'"')
        end
      end
      attrib, value = next( self, attrib )
    end
    result = result..func ('>')
  end

  -- then go recursively on the child elements
  if self.contain then   
    if self.separator then
      result = result..func (self.separator)
    end
    local i = 1
    while self.contain[i] do
      value = self.contain[i]
      if value == HtmlTag.Mark then
        HtmlTag.mark_counter = HtmlTag.mark_counter+1
      end
      if type(value) == 'table' and value.tag then
        result = result..value:toStream (func)
      elseif type(value) == 'string' or type(value) == 'number' then
        result = result..func (value)
      end
      if self.separator then
        result = result..func (self.separator)
      end
      i = i + 1
    end
  end

  if (self.contain or self.close) and self.tag ~= '' then
    result = result..func ('</'..self.tag..'>')
  end

  return result
end


-----------------------------------------------------------------------------
-- Calls Lua's error function to send error messages.

function HtmlTag:Error( str )
  error ( 'Error on Html tag. '..str )
end


-----------------------------------------------------------------------------
-- Called for checking fields that must be present
-- in the element newly created.

function HtmlTag:AttribRequired ( a, attrib_type )
  if not self[a] then
    self:Error ('Attribute "'..a..'" is required for <'.. self.tag ..'> tag.')
  end
  if attrib_type then
    if type (attrib_type) == 'table' then
      local i = 1
      while attrib_type[i] do
        if self[a] == attrib_type[i] then
          return self[a]
        end
        i = i+1
      end
      self.Error ('Attribute '..a..' of <'..self.tag..'> is not correct. ')
    elseif type ( self[a] ) ~= attrib_type and
		(type (self[a]) ~= 'number' or attrib_type ~= 'string') then
      self.Error ('Attribute '..a..' of <'..self.tag..'> tag must be a '..
                  attrib_type..' type. ')
    end
  end
  return self[a]
end


-----------------------------------------------------------------------------
-- Applies modifications the fields specifies,
-- acting recursively on the child elements.

function HtmlTag:ApplyOnFields( string_of_fields, what_to_apply, func_param  )
  local fields
  local component, value 
  local result
  local i = 1

  if type( string_of_fields ) == 'string' then
    fields = strsplit( string_of_fields, ",")
  else
    fields = string_of_fields
  end

  while fields[i] do

    if self[fields[i]] then
      if type( what_to_apply ) == 'string' then

        -- case of replacing one field with another
        if self[what_to_apply] then
          self[fields[i]] = self[what_to_apply]
          self[what_to_apply] = nil
        else
        -- new value for the field
          self[fields[i]] = what_to_apply
        end

      -- second parameter is a function
      elseif type( what_to_apply ) == 'function' then
        self[fields[i]] = what_to_apply( func_param )
      end
    end

    i = i + 1
  end

  if self.contain then  
    component, value = next( self.contain, nil )

    while component do
      if type(value) == 'table' and value.tag then
        value:ApplyOnFields( fields, what_to_apply, func_param  )
      end

      component, value = next( self.contain, component )
    end
  end
end


-----------------------------------------------------------------------------

A_Descriptor = HtmlTag:DeclareTag {
  tag = "a",
  close = 1,
  fields = {
  }
}

ABBR_Descriptor = HtmlTag:DeclareTag {
  tag = "abbr",
  close = 1,
  fields = {
  }
}

ABBREV_Descriptor = HtmlTag:DeclareTag {
  tag = "abbrev",
  fields = {
  }
}

ACRONYM_Descriptor = HtmlTag:DeclareTag {
  tag = "acronym",
  close = 1,
  fields = {
  }
}

ADDRESS_Descriptor = HtmlTag:DeclareTag {
  tag = "address",
  close = 1,
  fields = {
  }
}

APP_Descriptor = HtmlTag:DeclareTag {
  tag = "app",
  fields = {
  }
}

APPLET_Descriptor = HtmlTag:DeclareTag {
  tag = "applet",
  fields = {
    code = { HtmlTag.AttribRequired , 'string' },
    width = { HtmlTag.AttribRequired , 'string' },
    height = { HtmlTag.AttribRequired , 'string' },
  }
}

AREA_Descriptor = HtmlTag:DeclareTag {
  tag = "area",
  fields = {
    --alt = { HtmlTag.AttribRequired , 'string' },
  }
}

AU_Descriptor = HtmlTag:DeclareTag {
  tag = "au",
  fields = {
  }
}

B_Descriptor = HtmlTag:DeclareTag {
  tag = "b",
  close = 1,
  fields = {
  }
}

BANNER_Descriptor = HtmlTag:DeclareTag {
  tag = "banner",
  fields = {
  }
}

BASE_Descriptor = HtmlTag:DeclareTag {
  tag = "base",
  fields = {
    href = { HtmlTag.AttribRequired , 'string' },
  }
}

BASEFONT_Descriptor = HtmlTag:DeclareTag {
  tag = "basefont",
  fields = {
    size = { HtmlTag.AttribRequired , { 1,2,3,4,5,6,7 } },
  }
}

BDO_Descriptor = HtmlTag:DeclareTag {
  tag = "bdo",
  close = 1,
  fields = {
    dir = { HtmlTag.AttribRequired , { "ltr", "rtl" } },
  }
}

BGSOUND_Descriptor = HtmlTag:DeclareTag {
  tag = "bgsound",
  fields = {
    src = { HtmlTag.AttribRequired , 'string' },
  }
}

BIG_Descriptor = HtmlTag:DeclareTag {
  tag = "big",
  close = 1,
  fields = {
  }
}

BLINK_Descriptor = HtmlTag:DeclareTag {
  tag = "blink",
  fields = {
  }
}

BLOCKQUOTE_Descriptor = HtmlTag:DeclareTag {
  tag = "blockquote",
  close = 1,
  fields = {
  }
}

BODY_Descriptor = HtmlTag:DeclareTag {
  tag = "body",
  fields = {
  }
}

BOX_Descriptor = HtmlTag:DeclareTag {
  tag = "",
  fields = {
  }
}

BQ_Descriptor = HtmlTag:DeclareTag {
  tag = "bq",
  fields = {
  }
}

BR_Descriptor = HtmlTag:DeclareTag {
  tag = "br",
  fields = {
  }
}

BUTTON_Descriptor = HtmlTag:DeclareTag {
  tag = "button",
  close = 1,
  fields = {
  }
}

CAPTION_Descriptor = HtmlTag:DeclareTag {
  tag = "caption",
  close = 1,
  fields = {
  }
}

CENTER_Descriptor = HtmlTag:DeclareTag {
  tag = "center",
  close = 1,
  fields = {
  }
}

CITE_Descriptor = HtmlTag:DeclareTag {
  tag = "cite",
  close = 1,
  fields = {
  }
}

CODE_Descriptor = HtmlTag:DeclareTag {
  tag = "code",
  close = 1,
  fields = {
  }
}

COL_Descriptor = HtmlTag:DeclareTag {
  tag = "col",
  fields = {
  }
}

COLGROUP_Descriptor = HtmlTag:DeclareTag {
  tag = "colgroup",
  fields = {
  }
}

CREDIT_Descriptor = HtmlTag:DeclareTag {
  tag = "credit",
  fields = {
  }
}

DD_Descriptor = HtmlTag:DeclareTag {
  tag = "dd",
  fields = {
  }
}

DEL_Descriptor = HtmlTag:DeclareTag {
  tag = "del",
  close = 1,
  fields = {
  }
}

DFN_Descriptor = HtmlTag:DeclareTag {
  tag = "dfn",
  close = 1,
  fields = {
  }
}

DIR_Descriptor = HtmlTag:DeclareTag {
  tag = "dir",
  fields = {
  }
}

DIV_Descriptor = HtmlTag:DeclareTag {
  tag = "div",
  close = 1,
  fields = {
  }
}

DL_Descriptor = HtmlTag:DeclareTag {
  tag = "dl",
  close = 1,
  fields = {
  }
}

DT_Descriptor = HtmlTag:DeclareTag {
  tag = "dt",
  fields = {
  }
}

EM_Descriptor = HtmlTag:DeclareTag {
  tag = "em",
  close = 1,
  fields = {
  }
}

EMBED_Descriptor = HtmlTag:DeclareTag {
  tag = "embed",
  fields = {
    src = { HtmlTag.AttribRequired , 'string' },
  }
}

FIELDSET_Descriptor = HtmlTag:DeclareTag {
  tag = "fieldset",
  close = 1,
  fields = {
  }
}

FIG_Descriptor = HtmlTag:DeclareTag {
  tag = "fig",
  fields = {
    src = { HtmlTag.AttribRequired , 'string' },
  }
}

FN_Descriptor = HtmlTag:DeclareTag {
  tag = "fn",
  fields = {
    id = { HtmlTag.AttribRequired , 'string' },
  }
}

FONT_Descriptor = HtmlTag:DeclareTag {
  tag = "font",
  fields = {
  }
}

FORM_Descriptor = HtmlTag:DeclareTag {
  tag = "form",
  close = 1,
  fields = {
    action = { HtmlTag.AttribRequired , 'string' },
  }
}

FRAME_Descriptor = HtmlTag:DeclareTag {
  tag = "frame",
  fields = {
  }
}

FRAMESET_Descriptor = HtmlTag:DeclareTag {
  tag = "frameset",
  fields = {
  }
}

H1_Descriptor = HtmlTag:DeclareTag {
  tag = "h1",
  close = 1,
  fields = {
  }
}

H2_Descriptor = HtmlTag:DeclareTag {
  tag = "h2",
  close = 1,
  fields = {
  }
}

H3_Descriptor = HtmlTag:DeclareTag {
  tag = "h3",
  close = 1,
  fields = {
  }
}

H4_Descriptor = HtmlTag:DeclareTag {
  tag = "h4",
  close = 1,
  fields = {
  }
}

H5_Descriptor = HtmlTag:DeclareTag {
  tag = "h5",
  close = 1,
  fields = {
  }
}

H6_Descriptor = HtmlTag:DeclareTag {
  tag = "h6",
  close = 1,
  fields = {
  }
}

HEAD_Descriptor = HtmlTag:DeclareTag {
  tag = "head",
  fields = {
  }
}

HR_Descriptor = HtmlTag:DeclareTag {
  tag = "hr",
  fields = {
  }
}

HTML_Descriptor = HtmlTag:DeclareTag {
  tag = "html",
  fields = {
  }
}

I_Descriptor = HtmlTag:DeclareTag {
  tag = "i",
  close = 1,
  fields = {
  }
}

IFRAME_Descriptor = HtmlTag:DeclareTag {
  tag = "i",
  close = 1,
  fields = {
  }
}

IMG_Descriptor = HtmlTag:DeclareTag {
  tag = "img",
  fields = {
    src = { HtmlTag.AttribRequired , 'string' },
  }
}

INPUT_Descriptor = HtmlTag:DeclareTag {
  tag = "input",
  fields = {
  }
}

INS_Descriptor = HtmlTag:DeclareTag {
  tag = "ins",
  close = 1,
  fields = {
  }
}

ISINDEX_Descriptor = HtmlTag:DeclareTag {
  tag = "isindex",
  fields = {
  }
}

KBD_Descriptor = HtmlTag:DeclareTag {
  tag = "kbd",
  close = 1,
  fields = {
  }
}

LABEL_Descriptor = HtmlTag:DeclareTag {
  tag = "label",
  fields = {
  }
}

LANG_Descriptor = HtmlTag:DeclareTag {
  tag = "lang",
  close = 1,
  fields = {
  }
}

LEGEND_Descriptor = HtmlTag:DeclareTag {
  tag = "legend",
  close = 1,
  fields = {
  }
}

LH_Descriptor = HtmlTag:DeclareTag {
  tag = "lh",
  fields = {
  }
}

LI_Descriptor = HtmlTag:DeclareTag {
  tag = "li",
  fields = {
  }
}

LINK_Descriptor = HtmlTag:DeclareTag {
  tag = "link",
  fields = {
    href = { HtmlTag.AttribRequired , 'string' },
  }
}

LISTING_Descriptor = HtmlTag:DeclareTag {
  tag = "listing",
  fields = {
  }
}

MAP_Descriptor = HtmlTag:DeclareTag {
  tag = "map",
  close = 1,
  fields = {
    name = { HtmlTag.AttribRequired , 'string' },
  }
}

MARQUEE_Descriptor = HtmlTag:DeclareTag {
  tag = "marquee",
  fields = {
  }
}

MENU_Descriptor = HtmlTag:DeclareTag {
  tag = "menu",
  fields = {
  }
}

META_Descriptor = HtmlTag:DeclareTag {
  tag = "meta",
  fields = {
    content = { HtmlTag.AttribRequired , 'string' },
  }
}

NEXTID_Descriptor = HtmlTag:DeclareTag {
  tag = "nextid",
  fields = {
    n = { HtmlTag.AttribRequired , 'string' },
  }
}

NOBR_Descriptor = HtmlTag:DeclareTag {
  tag = "nobr",
  fields = {
  }
}

NOEMBED_Descriptor = HtmlTag:DeclareTag {
  tag = "noembed",
  fields = {
  }
}

NOFRAMES_Descriptor = HtmlTag:DeclareTag {
  tag = "noframes",
  fields = {
  }
}

NOSCRIPT = HtmlTag:DeclareTag {
  tag = "noscript",
  close = 1,
  fields = {
  }
}

NOTE_Descriptor = HtmlTag:DeclareTag {
  tag = "note",
  fields = {
  }
}

OBJECT_Descriptor = HtmlTag:DeclareTag {
  tag = "object",
  close = 1,
  fields = {
  }
}

OL_Descriptor = HtmlTag:DeclareTag {
  tag = "ol",
  close = 1,
  fields = {
  }
}

OPTGROUP_Descriptor = HtmlTag:DeclareTag {
  tag = "optgroup",
  close = 1,
  fields = {
    label = { HtmlTag.AttribRequired , 'string' },
  }
}

OPTION_Descriptor = HtmlTag:DeclareTag {
  tag = "option",
  fields = {
  }
}

OVERLAY_Descriptor = HtmlTag:DeclareTag {
  tag = "overlay",
  fields = {
    src = { HtmlTag.AttribRequired , 'string' },
  }
}

P_Descriptor = HtmlTag:DeclareTag {
  tag = "p",
  fields = {
  }
}

PARAM_Descriptor = HtmlTag:DeclareTag {
  tag = "param",
  fields = {
    name = { HtmlTag.AttribRequired , 'string' },
  }
}

PERSON_Descriptor = HtmlTag:DeclareTag {
  tag = "person",
  fields = {
  }
}

PLAINTEXT_Descriptor = HtmlTag:DeclareTag {
  tag = "plaintext",
  fields = {
  }
}

PRE_Descriptor = HtmlTag:DeclareTag {
  tag = "pre",
  close = 1,
  fields = {
  }
}

Q_Descriptor = HtmlTag:DeclareTag {
  tag = "q",
  close = 1,
  fields = {
  }
}

S_Descriptor = HtmlTag:DeclareTag {
  tag = "s",
  close = 1,
  fields = {
  }
}

SAMP_Descriptor = HtmlTag:DeclareTag {
  tag = "samp",
  close = 1,
  fields = {
  }
}

SCRIPT_Descriptor = HtmlTag:DeclareTag {
  tag = "script",
  close = 1,
  fields = {
    language = { HtmlTag.AttribRequired , 'string' },
  }
}

SELECT_Descriptor = HtmlTag:DeclareTag {
  tag = "select",
  close = 1,
  fields = {
  }
}

SMALL_Descriptor = HtmlTag:DeclareTag {
  tag = "small",
  close = 1,
  fields = {
  }
}

SPAN_Descriptor = HtmlTag:DeclareTag {
  tag = "span",
  close = 1,
  fields = {
  }
}

STRIKE_Descriptor = HtmlTag:DeclareTag {
  tag = "strike",
  fields = {
  }
}

STRONG_Descriptor = HtmlTag:DeclareTag {
  tag = "strong",
  close = 1,
  fields = {
  }
}

STYLE_Descriptor = HtmlTag:DeclareTag {
  tag = "style",
  close = 1,
  fields = {
    type = { HtmlTag.AttribRequired , 'string' },
  }
}

SUB_Descriptor = HtmlTag:DeclareTag {
  tag = "sub",
  close = 1,
  fields = {
  }
}

SUP_Descriptor = HtmlTag:DeclareTag {
  tag = "sup",
  close = 1,
  fields = {
  }
}

TAB_Descriptor = HtmlTag:DeclareTag {
  tag = "tab",
  fields = {
  }
}

TABLE_Descriptor = HtmlTag:DeclareTag {
  tag = "table",
  close = 1,
  fields = {
  }
}

TBODY_Descriptor = HtmlTag:DeclareTag {
  tag = "tbody",
  fields = {
  }
}

TD_Descriptor = HtmlTag:DeclareTag {
  tag = "td",
  fields = {
  }
}

TEXTAREA_Descriptor = HtmlTag:DeclareTag {
  tag = "textarea",
  close = 1,
  fields = {
    rows = { HtmlTag.AttribRequired , 'string' },
    cols = { HtmlTag.AttribRequired , 'string' },
  }
}

TFOOT_Descriptor = HtmlTag:DeclareTag {
  tag = "tfoot",
  fields = {
  }
}

TH_Descriptor = HtmlTag:DeclareTag {
  tag = "th",
  fields = {
  }
}

THEAD_Descriptor = HtmlTag:DeclareTag {
  tag = "thead",
  fields = {
  }
}

TITLE_Descriptor = HtmlTag:DeclareTag {
  tag = "title",
  close = 1,
  fields = {
  }
}

TR_Descriptor = HtmlTag:DeclareTag {
  tag = "tr",
  fields = {
  }
}

TT_Descriptor = HtmlTag:DeclareTag {
  tag = "tt",
  close = 1,
  fields = {
  }
}

U_Descriptor = HtmlTag:DeclareTag {
  tag = "u",
  fields = {
  }
}

UL_Descriptor = HtmlTag:DeclareTag {
  tag = "ul",
  close = 1,
  fields = {
  }
}

VAR_Descriptor = HtmlTag:DeclareTag {
  tag = "var",
  close = 1,
  fields = {
  }
}

WBR_Descriptor = HtmlTag:DeclareTag {
  tag = "wbr",
  fields = {
  }
}

XMP_Descriptor = HtmlTag:DeclareTag {
  tag = "xmp",
  fields = {
  }
}


-----------------------------------------------------------------------------

function A (param)
  return A_Descriptor:BuildElement(param)
end

function ABBR (param)
  return ABBR_Descriptor:BuildElement(param)
end

function ABBREV (param)
  return ABBREV_Descriptor:BuildElement(param)
end

function ACRONYM (param)
  return ACRONYM_Descriptor:BuildElement(param)
end

function ADDRESS (param)
  return ADDRESS_Descriptor:BuildElement(param)
end

function APP (param)
  return APP_Descriptor:BuildElement(param)
end

function APPLET (param)
  return APPLET_Descriptor:BuildElement(param)
end

function AREA (param)
  return AREA_Descriptor:BuildElement(param)
end

function AU (param)
  return AU_Descriptor:BuildElement(param)
end

function B (param)
  return B_Descriptor:BuildElement(param)
end

function BANNER (param)
  return BANNER_Descriptor:BuildElement(param)
end

function BASE (param)
  return BASE_Descriptor:BuildElement(param)
end

function BASEFONT (param)
  return BASEFONT_Descriptor:BuildElement(param)
end

function BDO (param)
  return BDO_Descriptor:BuildElement(param)
end

function BGSOUND (param)
  return BGSOUND_Descriptor:BuildElement(param)
end

function BIG (param)
  return BIG_Descriptor:BuildElement(param)
end

function BLINK (param)
  return BLINK_Descriptor:BuildElement(param)
end

function BLOCKQUOTE (param)
  return BLOCKQUOTE_Descriptor:BuildElement(param)
end

function BODY (param)
  return BODY_Descriptor:BuildElement(param)
end

function BOX (param)
  return BOX_Descriptor:BuildElement(param)
end

function BQ (param)
  return BQ_Descriptor:BuildElement(param)
end

function BR (param)
  return BR_Descriptor:BuildElement(param)
end

function BUTTON (param)
  return BUTTON_Descriptor:BuildElement(param)
end

function CAPTION (param)
  return CAPTION_Descriptor:BuildElement(param)
end

function CENTER (param)
  return CENTER_Descriptor:BuildElement(param)
end

function CITE (param)
  return CITE_Descriptor:BuildElement(param)
end

function CODE (param)
  return CODE_Descriptor:BuildElement(param)
end

function COL (param)
  return COL_Descriptor:BuildElement(param)
end

function COLGROUP (param)
  return COLGROUP_Descriptor:BuildElement(param)
end

function CREDIT (param)
  return CREDIT_Descriptor:BuildElement(param)
end

function DD (param)
  return DD_Descriptor:BuildElement(param)
end

function DEL (param)
  return DEL_Descriptor:BuildElement(param)
end

function DFN (param)
  return DFN_Descriptor:BuildElement(param)
end

function DIR (param)
  return DIR_Descriptor:BuildElement(param)
end

function DIV (param)
  return DIV_Descriptor:BuildElement(param)
end

function DL (param)
  return DL_Descriptor:BuildElement(param)
end

function DT (param)
  return DT_Descriptor:BuildElement(param)
end

function EM (param)
  return EM_Descriptor:BuildElement(param)
end

function EMBED (param)
  return EMBED_Descriptor:BuildElement(param)
end

function FIELDSET (param)
  return FIELDSET_Descriptor:BuildElement(param)
end

function FIG (param)
  return FIG_Descriptor:BuildElement(param)
end

function FN (param)
  return FN_Descriptor:BuildElement(param)
end

function FONT (param)
  return FONT_Descriptor:BuildElement(param)
end

function FORM (param)
  return FORM_Descriptor:BuildElement(param)
end

function FRAME (param)
  return FRAME_Descriptor:BuildElement(param)
end

function FRAMESET (param)
  return FRAMESET_Descriptor:BuildElement(param)
end

function H1 (param)
  return H1_Descriptor:BuildElement(param)
end

function H2 (param)
  return H2_Descriptor:BuildElement(param)
end

function H3 (param)
  return H3_Descriptor:BuildElement(param)
end

function H4 (param)
  return H4_Descriptor:BuildElement(param)
end

function H5 (param)
  return H5_Descriptor:BuildElement(param)
end

function H6 (param)
  return H6_Descriptor:BuildElement(param)
end

function HEAD (param)
  return HEAD_Descriptor:BuildElement(param)
end

function HR (param)
  return HR_Descriptor:BuildElement(param)
end

function HTML (param)
  return HTML_Descriptor:BuildElement(param)
end

function I (param)
  return I_Descriptor:BuildElement(param)
end

function IFRAME (param)
  return IFRAME_Descriptor:BuildElement(param)
end

function IMG (param)
  return IMG_Descriptor:BuildElement(param)
end

function INPUT (param)
  return INPUT_Descriptor:BuildElement(param)
end

function INS (param)
  return INS_Descriptor:BuildElement(param)
end

function ISINDEX (param)
  return ISINDEX_Descriptor:BuildElement(param)
end

function KBD (param)
  return KBD_Descriptor:BuildElement(param)
end

function LABEL (param)
  return LABEL_Descriptor:BuildElement(param)
end

function LANG (param)
  return LANG_Descriptor:BuildElement(param)
end

function LEGEND (param)
  return LEGEND_Descriptor:BuildElement(param)
end

function LH (param)
  return LH_Descriptor:BuildElement(param)
end

function LI (param)
  return LI_Descriptor:BuildElement(param)
end

function LINK (param)
  return LINK_Descriptor:BuildElement(param)
end

function LISTING (param)
  return LISTING_Descriptor:BuildElement(param)
end

function MAP (param)
  return MAP_Descriptor:BuildElement(param)
end

function MARQUEE (param)
  return MARQUEE_Descriptor:BuildElement(param)
end

function MENU (param)
  return MENU_Descriptor:BuildElement(param)
end

function META (param)
  return META_Descriptor:BuildElement(param)
end

function NEXTID (param)
  return NEXTID_Descriptor:BuildElement(param)
end

function NOBR (param)
  return NOBR_Descriptor:BuildElement(param)
end

function NOEMBED (param)
  return NOEMBED_Descriptor:BuildElement(param)
end

function NOFRAMES (param)
  return NOFRAMES_Descriptor:BuildElement(param)
end

function NOSCRIPT (param)
  return NOSCRIPT_Descriptor:BuildElement(param)
end

function NOTE (param)
  return NOTE_Descriptor:BuildElement(param)
end

function OBJECT (param)
  return OBJECT_Descriptor:BuildElement(param)
end

function OL (param)
  return OL_Descriptor:BuildElement(param)
end

function OPTGROUP (param)
  return OPTGROUP_Descriptor:BuildElement(param)
end

function OPTION (param)
  return OPTION_Descriptor:BuildElement(param)
end

function OVERLAY (param)
  return OVERLAY_Descriptor:BuildElement(param)
end

function P (param)
  return P_Descriptor:BuildElement(param)
end

function PARAM (param)
  return PARAM_Descriptor:BuildElement(param)
end

function PERSON (param)
  return PERSON_Descriptor:BuildElement(param)
end

function PLAINTEXT (param)
  return PLAINTEXT_Descriptor:BuildElement(param)
end

function PRE (param)
  return PRE_Descriptor:BuildElement(param)
end

function Q (param)
  return Q_Descriptor:BuildElement(param)
end

function S (param)
  return S_Descriptor:BuildElement(param)
end

function SAMP (param)
  return SAMP_Descriptor:BuildElement(param)
end

function SCRIPT (param)
  return SCRIPT_Descriptor:BuildElement(param)
end

function SELECT (param)
  return SELECT_Descriptor:BuildElement(param)
end

function SMALL (param)
  return SMALL_Descriptor:BuildElement(param)
end

function SPAN (param)
  return SPAN_Descriptor:BuildElement(param)
end

function STRIKE (param)
  return STRIKE_Descriptor:BuildElement(param)
end

function STRONG (param)
  return STRONG_Descriptor:BuildElement(param)
end

function STYLE (param)
  return STYLE_Descriptor:BuildElement(param)
end

function SUB (param)
  return SUB_Descriptor:BuildElement(param)
end

function SUP (param)
  return SUP_Descriptor:BuildElement(param)
end

function TAB (param)
  return TAB_Descriptor:BuildElement(param)
end

function TABLE (param)
  return TABLE_Descriptor:BuildElement(param)
end

function TBODY (param)
  return TBODY_Descriptor:BuildElement(param)
end

function TD (param)
  return TD_Descriptor:BuildElement(param)
end

function TEXTAREA (param)
  return TEXTAREA_Descriptor:BuildElement(param)
end

function TFOOT (param)
  return TFOOT_Descriptor:BuildElement(param)
end

function TH (param)
  return TH_Descriptor:BuildElement(param)
end

function THEAD (param)
  return THEAD_Descriptor:BuildElement(param)
end

function TITLE (param)
  return TITLE_Descriptor:BuildElement(param)
end

function TR (param)
  return TR_Descriptor:BuildElement(param)
end

function TT (param)
  return TT_Descriptor:BuildElement(param)
end

function U (param)
  return U_Descriptor:BuildElement(param)
end

function UL (param)
  return UL_Descriptor:BuildElement(param)
end

function VAR (param)
  return VAR_Descriptor:BuildElement(param)
end

function WBR (param)
  return WBR_Descriptor:BuildElement(param)
end

function XMP (param)
  return XMP_Descriptor:BuildElement(param)
end

