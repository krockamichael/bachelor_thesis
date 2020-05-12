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

local class = require 'middleclass'

local colors = require 'moontastic.utils.colors'
local sys = require 'moontastic.utils.sys'
local glyphs = require 'moontastic.utils.glyphs'
local theme = sys.get_current_theme()

local Segment = require 'moontastic.segments.init'

local sysinfo = {}

sysinfo.Time = class('Time', Segment)
function sysinfo.Time:initialize(...)

	Segment.initialize(self, ...)
	
	self.bg = colors.background(theme.TIME_BG)
	self.fg = colors.foreground(theme.TIME_FG)

end

function sysinfo.Time:init()

	self.text = glyphs.TIME .. ' ' .. os.date("%H:%M:%S")

end

sysinfo.UserAtHost = class('UserAtHost', Segment)
function sysinfo.UserAtHost:initialize(...)

	Segment.initialize(self, ...)
	
	self.bg = colors.background(theme.USERATHOST_BG)
	self.fg = colors.foreground(theme.USERATHOST_FG)

end

function sysinfo.UserAtHost:init()

	self.text = io.popen('whoami', 'r'):read() .. '@' .. sys.get_hostname()

end

return sysinfo