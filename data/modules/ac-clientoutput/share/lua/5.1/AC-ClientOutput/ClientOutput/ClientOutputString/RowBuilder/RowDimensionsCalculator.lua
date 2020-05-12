---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

---
-- Calculates the start and end positions of string rows based on a StringParser instance.
--
-- @type RowDimensionsCalculator
--
local RowDimensionsCalculator = {}


---
-- The minimum row length
--
-- @tfield int minimumRowLength
--
RowDimensionsCalculator.minimumRowLength = nil


-- Metamethods

---
-- RowDimensionsCalculator constructor.
-- This is the __call metamethod.
--
-- @tparam int _minimumRowLength The minimum row length
--
-- @treturn RowDimensionsCalculator The RowDimensionsCalculator instance
--
function RowDimensionsCalculator:__construct(_minimumRowLength)
  local instance = setmetatable({}, {__index = RowDimensionsCalculator})
  instance.minimumRowLength = _minimumRowLength

  return instance
end


-- Getters and Setters

---
-- Sets the minimum row length.
--
-- @tparam int _minimumRowLength The minimum row length
--
function RowDimensionsCalculator:setMinimumRowLength(_minimumRowLength)
  self.minimumRowLength = _minimumRowLength
end


-- Public Methods

---
-- Returns the next rows start position based on a minmium character number.
-- Will return nil if its not the first row and there are no more non whitespace characters.
--
-- @tparam ParsedString _parsedString The parsed string
-- @tparam int _minimumCharacterNumber The minimum character number inside the target string
--
-- @treturn int|nil The next rows start position or nil if no next start position could be found
--
function RowDimensionsCalculator:getNextStartPosition(_parsedString, _minimumCharacterNumber)

  if (_minimumCharacterNumber == 1) then
    return 1
  else
    return _parsedString:getNextNonWhitespacePositionTo(_minimumCharacterNumber)
  end

end

---
-- Returns the next rows end position based on a maximum character number.
--
-- @tparam ParsedString _parsedString The parsed string
-- @tparam int _maximumCharacterNumber The maximum character number inside the target string
-- @tparam bool _isLastRow True if the next row is the last row
--
-- @treturn int The next rows end position
--
function RowDimensionsCalculator:getNextEndPosition(_parsedString, _maximumCharacterNumber, _isLastRow)

  if (_isLastRow) then
    return _maximumCharacterNumber
  else

    local rowEndPosition = self:calculateNextRowEndPosition(_parsedString, _maximumCharacterNumber)
    if (rowEndPosition == nil or rowEndPosition < self.minimumRowLength) then
      return self.minimumRowLength
    else
      return rowEndPosition
    end

  end

end


-- Private Methods

---
-- Calculates and returns the next rows end position.
-- Will return nil if there are line split characters defined but none were found in the current row.
--
-- @tparam ParsedString _parsedString The parsed string
-- @tparam int _maximumCharacterNumber The maximum character number inside the target string
--
-- @treturn int|nil The next rows end position or nil if no position could be found
--
function RowDimensionsCalculator:calculateNextRowEndPosition(_parsedString, _maximumCharacterNumber)

  if (_parsedString:getLineSplitCharacters() == nil) then
    -- No line split characters defined, split the string at the last possible character
    return _maximumCharacterNumber
  else

    local lineSplitCharacterPosition = _parsedString:getLastLineSplitCharacterPositionBefore(_maximumCharacterNumber)
    if (lineSplitCharacterPosition ~= nil) then
      return _parsedString:getLastNonWhitespacePositionBefore(lineSplitCharacterPosition)
    end
  end

end


-- When RowDimensionsCalculator() is called, call the __construct method
setmetatable(RowDimensionsCalculator, {__call = RowDimensionsCalculator.__construct})


return RowDimensionsCalculator
