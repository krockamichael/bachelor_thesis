---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

---
-- Calculates the width of strings in the clients consoles.
--
-- @type StringWidthCalculator
--
local StringWidthCalculator = {}


---
-- The width of the currently parsed strings and characters
--
-- @tfield int width
--
StringWidthCalculator.width = nil

---
-- The symbol width loader
--
-- @tfield SymbolWidthLoader symbolWidthLoader
--
StringWidthCalculator.symbolWidthLoader = nil

---
-- The tab stop calculator
--
-- @tfield TabStopCalculator tabStopCalculator
--
StringWidthCalculator.tabStopCalculator = nil


-- Metamethods

---
-- StringWidthCalculator constructor.
-- This is the __call metamethod.
--
-- @tparam SymbolWidthLoader _symbolWidthLoader The symbol width loader
-- @tparam TabStopCalculator _tabStopCalculator The tab stop calculator
--
-- @treturn StringWidthCalculator The StringWidthCalculator instance
--
function StringWidthCalculator:__construct(_symbolWidthLoader, _tabStopCalculator)

  local instance = setmetatable({}, {__index = StringWidthCalculator})
  instance.symbolWidthLoader = _symbolWidthLoader
  instance.tabStopCalculator = _tabStopCalculator
  instance.width = -1

  return instance

end


-- Getters and Setters

---
-- Returns the width of the currently parsed strings and characters.
--
-- @treturn int The width
--
function StringWidthCalculator:getWidth()
  return self.width
end

---
-- Sets the width.
--
-- @tparam int _width The width
--
function StringWidthCalculator:setWidth(_width)
  self.width = _width
end


-- Public Methods

---
-- Adds an entire strings width to the total width of this StringWidthCalculator.
--
-- @tparam string _string The string
--
function StringWidthCalculator:addString(_string)

  for character in _string:gsub("\f[A-Za-z0-9]", ""):gmatch(".") do
    self:addCharacter(character)
  end

end

---
-- Adds a single characters width to the total width of this StringWidthCalculator.
--
-- @tparam string _character The character
--
function StringWidthCalculator:addCharacter(_character)

  -- In "src/rendertext.cpp" the width calculation is done as follows:
  --   1. The initial width is the first character of the string
  --   2. Every character after that is added to the total width by adding its width + 1
  --
  -- However the whitespace width is added as "+ default character width" while the +1 for the pixel between
  -- the characters is omitted.
  -- This leads to a bug in the calculation when the first character of a string is a whitespace because
  -- that one is not supposed to have the +1 pixel added.
  --
  -- To replicate the same behaviour the initial width is set here accordingly.
  --
  if (self.width == -1 and _character == " ") then
    self.width = 0
  end

  if (_character == "\t") then
    self.width = self.tabStopCalculator:getNextTabStopPosition(self.width)
  else
    self.width = self.width + self.symbolWidthLoader:getCharacterWidth(_character) + 1
  end

end

---
-- Resets the width to its initial value.
--
function StringWidthCalculator:reset()
  self.width = -1
end

---
-- Returns the width of a specified string.
--
-- @tparam string _string The string
--
-- @treturn int The width of the string
--
function StringWidthCalculator:getStringWidth(_string)
  self:reset()
  self:addString(_string)
  return self.width
end


-- When StringWidthCalculator() is called, call the __construct method
setmetatable(StringWidthCalculator, {__call = StringWidthCalculator.__construct})


return StringWidthCalculator
