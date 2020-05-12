---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local ParsedString = require("AC-ClientOutput/ClientOutput/ClientOutputString/StringParser/ParsedString")

---
-- Searches a string for line split characters, whitespace groups and colors.
--
-- @type StringParser
--
local StringParser = {}


---
-- The line split characters to search for
--
-- @tfield string lineSplitCharacters
--
StringParser.lineSplitCharacters = ""


-- Loop variables

---
-- Stores whether the next parsed letter is a color
--
-- @tfield bool nextCharacterIsAColor
--
StringParser.nextCharacterIsAColor = false


-- Metamethods

---
-- StringParser constructor.
-- This is the __call metamethod.
--
-- @tparam string _lineSplitCharacters The line split characters
--
-- @treturn StringParser The StringParser instance
--
function StringParser:__construct(_lineSplitCharacters)
  local instance = setmetatable({}, {__index = StringParser})
  instance.lineSplitCharacters = _lineSplitCharacters

  return instance
end


-- Getters and Setters

---
-- Sets the line split characters.
--
-- @tparam string _lineSplitCharacters The line split characters
--
function StringParser:setLineSplitCharacters(_lineSplitCharacters)
  self.lineSplitCharacters = _lineSplitCharacters
end


-- Public Methods

---
-- Parses a string and returns a ParsedString instance.
--
-- @tparam string _string The string to parse
--
-- @treturn ParsedString The parsed string
--
function StringParser:parse(_string)

  local parsedString = ParsedString(_string, self.lineSplitCharacters)

  local characterNumber = 1
  for character in _string:gmatch(".") do
    self:parseCharacter(parsedString, characterNumber, character)
    characterNumber = characterNumber + 1
  end

  return parsedString

end


-- Private Methods

---
-- Resets this StringParser.
--
function StringParser:reset()
  self.nextCharacterIsAColor = false
end

---
-- Parses a single character into a parsed string.
--
-- @tparam ParsedString _parsedString The parsed string
-- @tparam int _characterNumber The character number inside the target string
-- @tparam string _character The character
--
function StringParser:parseCharacter(_parsedString, _characterNumber, _character)

  if (self.nextCharacterIsAColor) then
    self.nextCharacterIsAColor = false
    _parsedString:addColor(_characterNumber - 1, "\f" .. _character)

  elseif (_character == "\f") then
    self.nextCharacterIsAColor = true

  elseif (_character == " " or _character == "\t") then
    _parsedString:addWhitespaceGroupCharacterPosition(_characterNumber, _character)

  elseif (_character:match(self.lineSplitCharacters)) then
    _parsedString:addLineSplitCharacterPosition(_characterNumber, _character)
  end

end


-- When StringParser() is called, call the __construct method
setmetatable(StringParser, {__call = StringParser.__construct})


return StringParser
