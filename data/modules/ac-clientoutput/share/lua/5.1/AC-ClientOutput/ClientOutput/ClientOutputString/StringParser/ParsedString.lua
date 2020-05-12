---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

---
-- Contains information about a string and provides methods to use these informations.
--
-- @type ParsedString
--
local ParsedString = {}


---
-- The string for which this ParsedString stores the results
--
-- @tfield string string
--
ParsedString.string = nil

---
-- The line split characters that were used to generate the results for this ParsedString
--
-- @tfield string|nil lineSplitCharacters
--
ParsedString.lineSplitCharacters = nil


---
-- The line split character positions inside the target string
-- This list is in the format { position, ... }
--
-- @tfield int[] lineSplitCharacterPositions
--
ParsedString.lineSplitCharacterPositions = {}

---
-- The list of line split characters
-- This list is in the format { [position] = string, ... }
--
-- @tfield string[] lineSplitCharacterList
--
ParsedString.lineSplitCharacterList = {}

---
-- The whitespace group positions inside the target string
-- Whitespaces and tabs will be added to whitespace groups
-- This list is in the format { { start = int, end = int }, ... }
--
-- @tfield table[] whitespaceGroupPositions
--
ParsedString.whitespaceGroups = {}

---
-- The positions of colors inside the target string
-- The list is in the format { [position] = <color string>, ... }
--
-- @tfield table colors
--
ParsedString.colors = {}

---
-- The current whitespace group
--
-- @tfield table currentWhitespaceGroup
--
ParsedString.currentWhitespaceGroup = nil


-- Metamethods

---
-- ParsedString constructor.
-- This is the __call metamethod.
--
-- @tparam string _string The original string
-- @tparam string|nil _lineSplitCharacters The line split characters
--
-- @treturn ParsedString The ParsedString instance
--
function ParsedString:__construct(_string, _lineSplitCharacters)

  local instance = setmetatable({}, {__index = ParsedString})

  instance.string = _string
  instance.lineSplitCharacters = _lineSplitCharacters
  instance.lineSplitCharacterList = {}
  instance.lineSplitCharacterPositions = {}
  instance.whitespaceGroups = {}
  instance.colors = {}

  return instance

end


-- Getters and Setters

---
-- Returns the target string.
--
-- @treturn string The target string
--
function ParsedString:getString()
  return self.string
end

---
-- Returns the line split characters that were used to generate this ParsedString's results.
--
-- @treturn string|nil The line split characters
--
function ParsedString:getLineSplitCharacters()
  return self.lineSplitCharacters
end


-- Public Methods

-- Add positions

---
-- Adds a color to this ParsedString.
--
-- @tparam int _position The position of the color
-- @tparam string _colorString The color string
--
function ParsedString:addColor(_position, _colorString)
  self.colors[_position] = _colorString
end

---
-- Adds a whitespace group character position to this ParsedString.
--
-- @tparam int _position The position of the whitespace group character
-- @tparam string _character The character
--
function ParsedString:addWhitespaceGroupCharacterPosition(_position, _character)

  if (self.currentWhitespaceGroup and self.currentWhitespaceGroup["end"] == _position - 1) then
    -- Extend the current whitespace group
    self.currentWhitespaceGroup["end"] = _position

  else
    -- Create a new whitespace group
    self.currentWhitespaceGroup = {
      ["start"] = _position,
      ["end"] = _position
    }
    table.insert(self.whitespaceGroups, self.currentWhitespaceGroup)
  end

  if (self.lineSplitCharacters and _character:match(self.lineSplitCharacters)) then
    self:addLineSplitCharacterPosition(_position, _character)
  end

end

---
-- Adds a line split character position to this ParsedString.
--
-- @tparam int _position The position of the line split character
-- @tparam string _character The character
--
function ParsedString:addLineSplitCharacterPosition(_position, _character)
  self.lineSplitCharacterList[_position] = _character
  table.insert(self.lineSplitCharacterPositions, _position)
end


-- Fetch information

---
-- Returns whether a string position is a color position.
--
-- @tparam int _position The position
--
-- @treturn bool True if the position is a color position, false otherwise
--
function ParsedString:isColorPosition(_position)
  return (self.colors[_position] ~= nil or self.colors[_position - 1] ~= nil)
end

---
-- Returns whether a string position is a line split character position.
--
-- @tparam int _position The position
--
-- @treturn bool True if the position is a line split character position, false otherwise
--
function ParsedString:isLineSplitCharacterPosition(_position)
  return (self.lineSplitCharacterList[_position] ~= nil)
end

---
-- Returns whether a string position is a start or end position of a whitespace group.
--
-- @tparam int _position The position
--
-- @treturn bool True if the position is a line split character position, false otherwise
--
function ParsedString:isAtWhitespaceGroupBorderPosition(_position)

  local whitespaceGroup = self:getWhitespaceGroupContainingPosition(_position, 1)
  if (whitespaceGroup == nil) then
    return false
  else
    return (whitespaceGroup["start"] == _position or whitespaceGroup["end"] == _position)
  end

end


---
-- Returns the last color before a specified string position.
--
-- @tparam int _position The position
--
-- @treturn string|nil The color string or nil if no color was found
--
function ParsedString:getLastColorBefore(_position)

  local lastColorBeforePosition
  for colorPosition, color in pairs(self.colors) do

    if (colorPosition + 1 < _position) then
      lastColorBeforePosition = color
    else
      break
    end

  end

  return lastColorBeforePosition

end

---
-- Returns the last line split character position before a specified string position.
--
-- @tparam int _position The position
--
-- @treturn int The last line split character position or nil if there is no line split character
--
function ParsedString:getLastLineSplitCharacterPositionBefore(_position)

  local lastLineSplitCharacterPosition
  for _, position in ipairs(self.lineSplitCharacterPositions) do
    if (position <= _position) then
      lastLineSplitCharacterPosition = position
    else
      break
    end
  end

  return lastLineSplitCharacterPosition

end

---
-- Returns the next string position that is not inside a whitespace group relative to a specified position.
--
-- @tparam int _position The position
--
-- @treturn int The next non whitespace group position
--
function ParsedString:getNextNonWhitespacePositionTo(_position)

  local whitespaceGroup = self:getWhitespaceGroupContainingPosition(_position)
  if (whitespaceGroup == nil) then
    return _position
  else
    return whitespaceGroup["end"] + 1
  end

end

---
-- Returns the last string position that is not inside a whitespace group relative from a specified position.
--
-- @tparam int _position The position
--
-- @treturn int The last non whitespace group position
--
function ParsedString:getLastNonWhitespacePositionBefore(_position)

  local whitespaceGroup = self:getWhitespaceGroupContainingPosition(_position)
  if (whitespaceGroup == nil) then
    return _position
  else
    return whitespaceGroup["start"] - 1
  end

end


-- Private Methods

---
-- Returns the whitespace group that contains a specified position.
-- Will return nil if no whitespace group was found that matches the conditions.
--
-- @tparam int _position The position
-- @tparam int _allowedDistance The allowed distance of the whitespace group to the position (optional)
--
-- @treturn table|nil The whitespace group that contains the position
--
function ParsedString:getWhitespaceGroupContainingPosition(_position, _allowedDistance)

  local startPosition = _position
  local endPosition = _position
  if (_allowedDistance ~= nil) then
    startPosition = startPosition + _allowedDistance
    endPosition = endPosition - _allowedDistance
  end

  for _, whitespaceGroup in ipairs(self.whitespaceGroups) do

    if (whitespaceGroup["start"] <= startPosition) then
      if (whitespaceGroup["end"] >= endPosition) then
        return whitespaceGroup
      end

    else
      break
    end

  end

end


-- When ParsedString() is called, call the __construct method
setmetatable(ParsedString, {__call = ParsedString.__construct})


return ParsedString
