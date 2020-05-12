#!/usr/bin/env lua

local gsub = gsub or string.gsub
local dostring = dostring
	or (loadstring and function (s) return assert(loadstring(s))() end)
	or (load and function (s) return assert(load(s))() end)
local date = date or os.date

htk = require"htk" -- global para ser visível pelo código gerado dinamicamente

function do_ex (s)
	local ss = dostring ("return "..s)
	ss = gsub (ss, "<", "&lt;")
	ss = gsub (ss, ">", "&gt;")
	return ss
end

function show_example (ex)
	return htk.TR {
		htk.TD { htk.SMALL { htk.PRE { "print("..ex..")" }, },},
		htk.TD { htk.SMALL { htk.PRE { do_ex (ex), },},},
		htk.TD { htk.SMALL { dostring("return "..ex) },},
	}
end

local navigation_bar = htk.P { align = "center", separator = "\n",
	htk.A { href = "#whatis", "what is", },
	"&middot;",
	htk.A { href = "#download", "download", },
	"&middot;",
	htk.A { href = "#ref", "reference", },
	"&middot;",
	htk.A { href = "#ex", "examples", },
	"&middot;",
	htk.A { href = "#news", "news", },
	"&middot;",
	htk.A { href = "#implementation", "implementation", },
}

local ex1 = [[htk.B { "Bold" }]]
local ex2 = [[htk.BIG {
  separator = "\n",
  "A sample ",
  htk.EM { "text" },
  " with some ",
  htk.B { "formatting tags" },
  htk.BR {},
}]]
local ex3 = [[htk.FORM {
  method = "POST",
  htk.TABLE {
    separator = "\n",
    border = true,
    htk.TEXT_FIELD {
      label = "Full name",
      separator = "\n",
      name = "name",
      value = "Write your name here",
    },
    htk.RADIO_FIELD {
      label = "Sex",
      separator = "\n",
      name = "sex",
      options = {
        { "Masc.", value = "M" },
        { "Fem.", value = "F" },
      },
    },
  },
}]]
local ex4 = [[htk.BOX {
  separator = '\n',
  htk.SELECT {
    multiple = true,
    name = "cities",
    value = "11",
    options = {
      { "Rio de Janeiro", value="1" },
      { "Friburgo", value="5" },
      { "Saquarema", value="11" },
      { "Cabo Frio", value="12" },
    },
  },
  htk.SELECT {
    multiple = true,
    name = "cities",
    value = "11,1",
    options = {
      { "Rio de Janeiro", value="1" },
      { "Friburgo", value="5" },
      { "Saquarema", value="11" },
      { "Cabo Frio", value="12" },
    },
  },
  htk.SELECT {
    multiple = true,
    name = "cities",
    value = "Friburgo,Cabo Frio",
    options = { "Rio de Janeiro", "Friburgo", "Saquarema", "Cabo Frio", },
  },
  htk.BR {},
  htk.RADIO {
    name = "cities",
    value = "Friburgo",
    options = { "Rio de Janeiro", "Friburgo", "Saquarema", "Cabo Frio", },
  },
}]]
local ex_class_defaults = [[htk.class_defaults.TD = "common"
print (htk.TR {
	htk.TD { "first" },
	htk.TD { "second", class = "special" },
	htk.TD { "third" },
	separator = "\n",
})]]

print (htk.HTML {
	htk.HEAD { htk.TITLE { "HTK", }, },
	htk.BODY {
		bgcolor = "#FFFFFF",
		separator = '\n',
		htk.HR {},
		htk.CENTER {
			htk.TABLE {
				border = 0,
				cellspacing = 2,
				cellpadding = 2,
				htk.TR { htk.TD { align = "center",
					htk.A {
						href = "http://www.lua.org",
						htk.IMG { alt = "The Lua Language", src = "lua.png", },
					},
				},},
				htk.TR { htk.TD { align = "center",
					htk.BIG { htk.B { "HTK", }, },
				},},
				htk.TR { htk.TD {
					align = "center",
					valign = "top",
					"A library of HTML constructors",
				},},
			},
		},
		navigation_bar,
		htk.HR {},

		-- What is
		htk.H2 { htk.A { name = "whatis", "What is HTK?", }, },
		"HTK is a library of ",
		htk.A { href = "http://www.lua.org", "Lua", },
		" functions that create HTML text.\n",
		"It was designed to be used within ",
		htk.A { href = "http://www.keplerproject.org/cgilua", "CGILua", },
		[[, however HTK does not depend on CGILua.]],
		htk.P {},
		[[HTK was developed to provide a structured way to build HTML
pages.
It has an homogeneuos API to all HTML elements despite their own
particularities: all pre-defined form-field values are set with ]],
		htk.TT { "value", },
		" attribute, even for multi-line fields (built with ",
		htk.EM { "TEXTAREA", },
		" constructor) or radio buttons (built with ",
		htk.EM { "RADIO", },
		" constructor).",

		-- Download and Installation
		htk.H2 { htk.A { name = "download", "Download and installation", }, },
		"The ",
		htk.B { "current version" },
		" of HTK source code can be freely downloaded from the following link:",
		htk.UL { htk.LI { htk.A { href = "htk.lua", htk._VERSION, }, },},
		"This version is just a reimplementation to make it compatible with all Lua 5.X versions.",
		htk.BR {},
		"You can install it in your LUA_PATH or using ",
		htk.A { href = "http://www.luarocks.org/", "LuaRocks", },
		".",
		"Older versions can be downloaded too:",
		htk.UL {
			htk.LI { htk.A { href = "htk-3.3.2.lua", "HTK 3.3.2", }, },
			htk.LI { htk.A { href = "htk-3.3.1.lua", "HTK 3.3.1", }, },
			htk.LI { htk.A { href = "htk-3.3.0.lua", "HTK 3.3.0", }, },
			htk.LI { htk.A { href = "htk-3.2.0.lua", "HTK 3.2.0", }, },
			htk.LI { htk.A { href = "htk-3.1.1.lua", "HTK 3.1.1", }, },
			htk.LI { htk.A { href = "htk-3.1.lua", "HTK 3.1", }, },
			htk.LI { htk.A { href = "htk-3.0.3.lua", "HTK 3.0.3", }, htk.SMALL {" (Lua 5.1)"}, },
			htk.LI { htk.A { href = "htk-3.0.2.lua", "HTK 3.0.2", }, },
			htk.LI { htk.A { href = "htk-3.0.1.lua", "HTK 3.0.1", }, },
			htk.LI { htk.A { href = "htk-3.0.lua", "HTK 3.0", }, htk.SMALL {" (Lua 5.0)"}, },
			htk.LI { htk.A { href = "htk-2.0.4.lua", "HTK 2.0.4", },},
			htk.LI { htk.A { href = "htk-2.0.3.lua", "HTK 2.0.3", },},
			htk.LI { htk.A { href = "htk-2.0.2.lua", "HTK 2.0.2", },},
			htk.LI { htk.A { href = "htk-2.0.1.lua", "HTK 2.0.1", },},
			htk.LI { htk.A { href = "htk-2.0.lua", "HTK 2.0", },},
			htk.LI { htk.A { href = "htk-1.2.lua", "HTK 1.2", },},
			htk.LI { htk.A { href = "htmltoolkit.lua", "HTMLToolkit", },},
		},

		-- Reference
		htk.H2 { htk.A { name = "ref", "Reference", }, },
		"HTK constructors can be divided in some groups:",
		htk.UL {
			htk.LI { htk.A { href = "#virtual", "Virtual", }, },
			htk.LI { htk.A { href = "#input", "Input", }, },
			htk.LI { htk.A { href = "#container", "Container", }, },
			htk.LI { htk.A { href = "#compound", "Compound", }, },
			htk.LI { htk.A { href = "#table_cell", "Table cells", }, },
			htk.LI { htk.A { href = "#table_row", "Table rows", }, },
			htk.LI { htk.A { href = "#class_defaults", "Default class attribute", }, },
		},

		-- Virtual constructors
		htk.H4 { htk.A { name = "virtual", }, "Virtual Constructors", },
		htk.DD {},
			htk.TT { "htk.FRAME" },
			" makes a rectangular frame around the elements inside it.",
		htk.DD {},
			htk.TT { "htk.MULTILINE" },
			[[ creates a text input element with multiple lines
(the same as a ]],
			htk.TT { "TEXTAREA" },
			" element).",

		-- Input constructors
		htk.H4 { htk.A { name = "input", }, "Input Constructors", },
		"All these constructors are short forms of the ",
		htk.TT { "INPUT" },
		" with the ",
		htk.EM { "type" },
		" attribute previously set.",
		htk.DD {}, htk.TT { "htk.BUTTON" },
		htk.DD {}, htk.TT { "htk.FILE" },
		htk.DD {}, htk.TT { "htk.HIDDEN" },
		htk.DD {}, htk.TT { "htk.PASSWORD" },
		htk.DD {}, htk.TT { "htk.RADIO_BUTTON" },
		htk.DD {}, htk.TT { "htk.RESET" },
		htk.DD {}, htk.TT { "htk.SUBMIT" },
		htk.DD {}, htk.TT { "htk.TEXT" },
		htk.DD {}, htk.TT { "htk.TOGGLE" },
		htk.P {},

		-- Container constructors
		htk.H4 { htk.A { name = "container", }, "Container Constructors", },
		[[These are constructors that group together some elements of the
same type.
In a group of radio buttons only one of them can be checked;
a group of options compound a selection list.]],
		htk.DD {},
			htk.TT { "htk.RADIO" },
			" creates a group of radio buttons (in HTML, these elements are of tag INPUT, with the TYPE attribute set to &quot;radio&quot;).",
		htk.DD {},
			htk.TT { "htk.TOGGLE_LIST" },
			" creates a group of toggles (in HTML, these elements are of tag INPUT, with the TYPE attribute set to &quot;checkbox&quot;).",
		htk.DD {},
			htk.TT { "htk.SELECT" },
			" creates a selection list (in HTML, this element is of tag SELECT, which should have some (or several) elements of tag OPTION inside it).",
		htk.P {},

		-- Compound constructors
		htk.H4 { htk.A { name = "compound", }, "Compound Constructors", },
		htk.DD {},
			htk.TT { "htk.COMPOUND" },
			" generic combinator of elements.",
		htk.DD {},
			htk.TT { "htk.DATE" },
			[[ creates a day-month-year date field:
the day-field is a two-character text field;
the month-field is a selection box;
the year-field is a four-character text field.
The default value format can be "dd/mmm/yyyy" or "yyyy-mm-dd"]],
		htk.P {},

		-- Table cell constructors
		htk.H4 { htk.A { name = "table_cell", }, "Table Cell Constructors", },
		"Both constructors extends the correspondent HTML elements to accept ",
		htk.TT { "face", },
		", ",
		htk.TT { "size", },
		" and ",
		htk.TT { "color", },
		" attributes and construct a ",
		htk.TT { "FONT" },
		" element inside the cell that will receive these attributes.",
		htk.DD {},
			htk.TT { "htk.TD" },
		htk.DD {},
			htk.TT { "htk.TH" },
		htk.P {},

		-- Table rows constructors
		htk.H4 { htk.A { name = "table_row", }, "Table Row Constructors", },
		[[The following constructors create a table row with two cells,
the left one with a "label" ("]],
		htk.TT { "label" },
		[[ attribute) and the right one with the correspondent input element.]],
		htk.DD {},
			htk.TT { "htk.DATE_FIELD" },
		htk.DD {},
			htk.TT { "htk.FILE_FIELD" },
		htk.DD {},
			htk.TT { "htk.MULTILINE_FIELD" },
		htk.DD {},
			htk.TT { "htk.PASSWORD_FIELD" },
		htk.DD {},
			htk.TT { "htk.RADIO_FIELD" },
		htk.DD {},
			htk.TT { "htk.SELECT_FIELD" },
		htk.DD {},
			htk.TT { "htk.TEXT_FIELD" },
		htk.DD {},
			htk.TT { "htk.TEXTAREA_FIELD" },
		htk.DD {},
			htk.TT { "htk.TOGGLE_FIELD" },
		htk.P {},

		-- Default value for class attribute
		htk.H4 { htk.A { name = "class_defaults", }, "Default value for class attribute", },
		[[HTK also provides a way to easily add a default value for the ]],
		htk.I { "class" },
		[[ attribute: the table ]],
		htk.TT { "class_defaults" },
		[[ can store the value of the class attribute for each element.
It is indexed by the name of the element and its value will be copied to
the resulting element if there is no definition of the class attribute.]],
		htk.BR {},
		[[For example, the following code:]],
		--htk.BR {},
		htk.PRE { ex_class_defaults },
		--htk.BR {},
		[[will generate the following output:]],
		htk.PRE { gsub (gsub (dostring (gsub (ex_class_defaults, "print", "return")), "<", "&lt;"), ">", "&gt;") },
		htk.P {},

		-- Examples
		htk.H2 { htk.A { name = "ex", "Examples", }, },
		[[Here are some small examples on how to use HTK.
The following table show three columns,
the first one with the Lua source code,
the second with the HTML source code generated by the library,
and the third with the rendered HTML code.]],
		htk.TABLE {
			border = true,
			htk.TR {
				htk.TH { htk.SMALL { "Lua source" },},
				htk.TH { htk.SMALL { "HTML generated" },},
				htk.TH { htk.SMALL { "Final result" },},
			},
			show_example (ex1),
			show_example (ex2),
			show_example (ex3),
			show_example (ex4),
		},
		[[This page was completely generated by HTK -- is its main test!]],
		[[The source code of this page can be downloaded by clicking ]],
		htk.A { href = "index.lua", "here", },
		htk.P {},

		-- News
		htk.H2 { htk.A { name = "news", "News", }, },
		htk.UL {
			htk.LI { "3.4 [4/mar/2013] ", "Specification clean up: SELECT, RADIO and TOGGLE_LIST default values must be specified values (in other words, one cannot pre-select an item by its position on the list anymore)", },
			htk.LI { "3.3.2 [20/feb/2013] ", "Bug fix: selected/checked items of SELECT, RADIO and TOGGLE_LIST were not correctly marked", htk.BR{}, "Add more SELECT examples", htk.BR{}, "Minor improvements on documentation (in this file).", },
			htk.LI { "3.3.1 [8/feb/2013] ", "Bug fix: selected similar values were intermixed.", },
			htk.LI { "3.3.0 [20/dec/2011] ", "New version updated to run for all Lua 5.X versions.", },
			htk.LI { "3.2.0 [08/nov/2010] ", "Improving option-element attribute definition", htk.BR{}, "Deployment via LuaRocks", },
			htk.LI { "3.1.1 [11/may/2007] ", "Bug fix: multiple selected values in checkboxes", },
			htk.LI { "3.1 [09/apr/2007] ", "Deprecated constructions removed", },
			htk.LI { "3.0.3 [30/may/2006] ", "New version updated to run with Lua 5.1", },
			htk.LI { "3.0.2 [25/jan/2006] ", "Bug fix: boolean value in attributes", },
			htk.LI { "3.0.1 [24/jan/2006] ", "Using ", htk.CODE {"module"}, " function", },
			htk.LI { "3.0 [13/out/2003] ", "New version updated to run with Lua 5.0", },
			htk.LI { "2.0.4 [21/aug/2003] ", "Bug fix (revisited): multiple selected values", },
			htk.LI {
				"2.0.3 [25/jul/2002] ",
				"New feature: ",
				htk.A { href = "#class_defaults",
					"default value for class attribute",
				},
			},
			htk.LI { "2.0.2 [25/apr/2002] ", "Bug fix: multiple selected values", },
			htk.LI { "2.0.1 [24/oct/2001] ", "Bug fix: closing tags", },
			htk.LI { "2.0 [15/oct/2001] ", "Version 2.0 released", },
			htk.LI {
				"1.2 [28/sep/2001] ",
				"Conforming to ",
				htk.A { href = "http://www.lua.org/notes/ltn007.html",
					"LTN 007 - Modules & Packages",
				},
			},
			htk.LI {
				"[26/mar/2001] ",
				"Bug fix on ",
				htk.I { "Table Rows", },
			},
		},
		htk.P {},

		-- Implementation
		htk.H2 { htk.A { name = "implementation", "Implementation", }, },
		"Originally, HTK was based on ",
		htk.A { href = "htmltoolkit.lua", "HTMLToolkit" },
		[[, a set of constructors that reflect in Lua exaclty how HTML
elements are built.
This approach brought all HTML's heterogeneity to the toolkit.
For example, a default value of a ]],
		htk.TT { "TEXT" },
		" field is set by the ",
		htk.TT { "value" },
		" attribute, but if the element is a ",
		htk.TT { "TEXTAREA" },
		[[, the field with index 1 must be set with the default value;
also, if the element is a ]],
		htk.TT { "SELECT" },
		", the corresponding ",
		htk.TT { "OPTION" },
		" element of the selection list must have a ",
		htk.TT { "selected" },
		" clause.",
		"So, ",
		htk.EM { "HTK" },
		" was built to be the homogeneous interface between Lua and HTML.",
		htk.P {},
		[[But with version 1.X, the programmer must know what constructors
are from HTK and what are the original from HTMLToolkit to write it down
properly.
Now, with version 2.0, HTMLToolkit was eliminated and all its constructors
were incorporated into HTK.]],
		htk.P {},
		[[Another difference to version 2.0 is the way the constructors are
build.  HTMLToolkit has a description table for each HTML element, almost
always with the same contents; and also, the elements are always created
as tables, its contents are checked (for some obligatory fields) and then
the resulting string is created.
Version 1.X of HTK depends on HTMLToolkit so it inherit all its functions.
On version 2.0, HTK incorporated all HTMLToolkit constructors but with
a different approach.
As almost all functions differ only in the name of the tag element,
now they're just one function, with many closures to make the difference.
Also, there are a constructor generator that only build the constructors
when they are called, so only the used constructors are really created.]],
		htk.P {},
		[[All these changes made version 2.0 at about 60% faster than
version 1.0.
Besides, the source code is about a third of the previous version,
making it easier to maintain, despite its complexity.]],
		htk.P {},

		-- Footer
		navigation_bar,
		htk.HR {},
		htk.TABLE {
			align = "center",
			separator = '\n',
			htk.TR {
				htk.TD { align = "center",
					htk.IMG {
						alt = "Created with Vim",
						src = "vim.png",
					},
				},
				htk.TD { align = "center", " and ", },
				htk.TD { align = "center",
					htk.IMG {
						alt = "Best Viewed on Any Browser",
						src = "anybrowser.png",
					},
				},
			},
			htk.TR {
				htk.TD { colspan = 3, align = "center",
					htk.SMALL {
						"Last modified by Tomás on ",
						htk.BR {},
						date (),
					},
				},
			},
		},
	},
})
