-- The MIT License (MIT)

-- Copyright (c) 2016 Ruairidh Carmichael - ruairidhcarmichael@live.co.uk

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

require 'moontastic.utils.string'

local class = require 'middleclass'

local colors = require 'moontastic.utils.colors'
local glyphs = require 'moontastic.utils.glyphs'
local sys = require 'moontastic.utils.sys'

local theme = sys.get_current_theme()

local Segment = require 'moontastic.segments.init'

local basics = {}

basics.NewLine = class('NewLine', Segment)
function basics.NewLine:initialize(...)

	Segment.initialize(self, ...)
	self.text = '\r\n'

end

basics.Root = class('Root', Segment)
function basics.Root:initialize(...)

	Segment.initialize(self, ...)
	self.text = '\\$ '

end

basics.Divider = class('Divider', Segment)
function basics.Divider:initialize(...)

	Segment.initialize(self, ...)
	self.text = glyphs.DIVIDER

end

function basics.Divider:set_colors(prev, next)

	if next.bg then self.bg = next.bg else self.bg = basics.Padding:new(0).bg end
	if prev.bg then self.fg = prev.bg else self.fg = basics.Padding:new(0).bg end
	self.fg = string.gsub(self.fg, 'setab', 'setaf')

end

basics.ExitCode = class('ExitCode', Segment)
function basics.ExitCode:initialize(...)

	Segment.initialize(self, ...)

	self.bg = colors.background(theme.EXITCODE_BG)
	self.fg = colors.foreground(theme.EXITCODE_FG)

end

function basics.ExitCode:init(...)

	self.text = ' ' .. glyphs.CROSS .. ' '

	if arg[1] == '0' then
		self.active = false
	end

end

basics.Padding = class('Padding', Segment)
function basics.Padding:initialize(...)

	Segment.initialize(self, ...)

	self.bg = colors.background(theme.PADDING_BG)

end

function basics.Padding:init(amount)

	self.text = string.ljust(self.text, ' ', amount)

end

return basics