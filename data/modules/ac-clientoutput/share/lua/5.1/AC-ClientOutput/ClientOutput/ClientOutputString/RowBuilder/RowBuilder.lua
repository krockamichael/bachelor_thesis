---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local RowDimensionsCalculator = require("AC-ClientOutput/ClientOutput/ClientOutputString/RowBuilder/RowDimensionsCalculator")
local StringWidthCalculator = require("AC-ClientOutput/ClientOutput/ClientOutputString/StringWidthCalculator")
local WidthCacher = require("AC-ClientOutput/ClientOutput/ClientOutputString/RowBuilder/WidthCacher")

---
-- Builds rows from a parent ClientOutputString's string.
--
-- @type RowBuilder
--
local RowBuilder = {}


---
-- The parent ClientOutputString
--
-- @tfield ClientOutputString parentClientOutputString
--
RowBuilder.parentClientOutputString = nil

---
-- The tab stop calculator
--
-- @tfield TabStopCalculator tabStopCalculator
--
RowBuilder.tabStopCalculator = nil

---
-- The StringWidthCalculator
--
-- @tfield StringWidthCalculator stringWidthCalculator
--
RowBuilder.stringWidthCalculator = nil

---
-- The RowDimensionsCalculator
--
-- @tfield RowDimensionsCalculator rowDimensionsCalculator
--
RowBuilder.rowDimensionsCalculator = nil

---
-- The WidthCacher
--
-- @tfield WidthCacher widthCacher
--
RowBuilder.widthCacher = nil


---
-- The parsed string from which the rows will be extracted
--
-- @tfield ParsedString parsedString
--
RowBuilder.parsedString = nil

---
-- The maximum width per row
--
-- @tfield int maximumLineWidth
--
RowBuilder.maximumLineWidth = nil

---
-- The start position of the current row inside the target string
--
-- @tfield int currentRowStartPosition
--
RowBuilder.currentRowStartPosition = nil

---
-- The last parsed position
--
-- @tfield int lastParsedPosition
--
RowBuilder.lastParsedPosition = nil


-- Metamethods

---
-- RowBuilder constructor.
-- This is the __call metamethod.
--
-- @tparam ClientOutputString _parentClientOutputString The parent ClientOutputString
-- @tparam SymbolWidthLoader _symbolWidthLoader The SymbolWidthLoader
-- @tparam TabStopCalculator _tabStopCalculator The TabStopCalculator
--
-- @treturn RowBuilder The RowBuilder instance
--
function RowBuilder:__construct(_parentClientOutputString, _symbolWidthLoader, _tabStopCalculator)

  local instance = setmetatable({}, {__index = RowBuilder})

  instance.parentClientOutputString = _parentClientOutputString
  instance.tabStopCalculator = _tabStopCalculator
  instance.stringWidthCalculator = StringWidthCalculator(_symbolWidthLoader, _tabStopCalculator)
  instance.rowDimensionsCalculator = RowDimensionsCalculator(1)
  instance.widthCacher = WidthCacher(2)

  return instance

end


-- Getters and Setters

---
-- Returns the current rows start position.
--
-- @treturn int The start position
--
function RowBuilder:getCurrentRowStartPosition()
  return self.currentRowStartPosition
end


-- Public Methods

---
-- Initializes this RowBuilder with a parsed string.
--
-- @tparam ParsedString _parsedString The parsed string
--
function RowBuilder:initialize(_parsedString)
  self.parsedString = _parsedString
  self:reset()
end

---
-- Returns whether the maximum line width is reached for the current row.
--
-- @treturn bool True if the maximum line width is reached for the current row, false otherwise
--
function RowBuilder:isMaximumLineWidthReached()
  return (self.stringWidthCalculator:getWidth() >= self.maximumLineWidth)
end

---
-- Parses a character into the current row.
--
-- @tparam int _characterNumber The character number
-- @tparam string _character The character
--
function RowBuilder:parseCharacter(_characterNumber, _character)

  if (not self.parsedString:isColorPosition(_characterNumber)) then
    self.stringWidthCalculator:addCharacter(_character)
  end

  local isCachePosition = (
    self.parsedString:isLineSplitCharacterPosition(_characterNumber + 1) or
    self.parsedString:isAtWhitespaceGroupBorderPosition(_characterNumber - 1)
  )

  -- Cache the width
  self.widthCacher:cacheTotalWidth(_characterNumber, self.stringWidthCalculator:getWidth(), isCachePosition)

  self.lastParsedPosition = _characterNumber

end

---
-- Builds the next row from the current information.
--
-- @tparam bool _isLastRow True if the next row is the last row
-- @tparam int|nil _padTabNumber The tab number until which the row shall be padded with tabs (optional)
--
-- @treturn string The next row string
--
function RowBuilder:buildNextRow(_isLastRow, _padTabNumber)

  local rowEndPosition = self.rowDimensionsCalculator:getNextEndPosition(self.parsedString, self.lastParsedPosition, _isLastRow)

  local isFirstRow = (self.currentRowStartPosition == 1)
  local rowString = self:extractNextRowString(rowEndPosition, isFirstRow, _padTabNumber)

  -- Update the current rows start position
  if (not _isLastRow) then
    self.currentRowStartPosition = self.rowDimensionsCalculator:getNextStartPosition(self.parsedString, rowEndPosition + 1)
  end

  -- Reset the width of the string width calculator
  self.stringWidthCalculator:reset()

  if (isFirstRow) then
    self:initializeAdditionalRowsIndent()
  end

  if (not _isLastRow) then
    self:initializeNextRowWidth()
  end

  return rowString

end

---
-- Resets the RowBuilder.
--
function RowBuilder:reset()

  self.maximumLineWidth = self.parentClientOutputString:getMaximumLineWidth()
  self.currentRowStartPosition = 1
  self.stringWidthCalculator:reset()
  self.widthCacher:reset()

end


-- Private Methods

---
-- Extracts the next row string from the current parsed string.
--
-- @tparam int _rowEndPosition The row end position inside the target string
-- @tparam bool _isFirstRow True if the row is the first row
-- @tparam int|nil _padTabNumber The tab number until which the row shall be padded with tabs (optional)
--
-- @treturn string The extracted row
--
function RowBuilder:extractNextRowString(_rowEndPosition, _isFirstRow,  _padTabNumber)

  local rowString
  if (_isFirstRow) then
    rowString = ""
  else

    rowString = self.parentClientOutputString:getNewLineIndent()
    local closestColor = self.parsedString:getLastColorBefore(_rowEndPosition)
    if (closestColor ~= nil) then
      rowString = rowString .. closestColor
    end

  end

  rowString = rowString .. self.parsedString:getString():sub(self.currentRowStartPosition, _rowEndPosition)
  if (_padTabNumber ~= nil) then
    rowString = rowString .. self:getPadTabsForCurrentRow(_rowEndPosition, _padTabNumber)
  end

  return rowString

end

---
-- Returns tabs to right pad the current row string until it reaches a specific tab stop.
--
-- @tparam int _rowEndPosition The row end position inside the target string
-- @tparam int _padTabNumber The tab number until which the row shall be padded with tabs (optional)
--
-- @treturn string The tabs to pad the row string
--
function RowBuilder:getPadTabsForCurrentRow(_rowEndPosition, _padTabNumber)
  local currentRowWidth = self.widthCacher:getWidthBetween(self.currentRowStartPosition, _rowEndPosition)
  return string.rep("\t", self.tabStopCalculator:getNumberOfTabsToTabStop(currentRowWidth, _padTabNumber))
end

---
-- Initializes the indent for additional rows.
-- This method adjusts the maximum line width and the minimum row length.
--
function RowBuilder:initializeAdditionalRowsIndent()

  local newLineIndent = self.parentClientOutputString:getNewLineIndent()
  local newLineIndentWidth = self.stringWidthCalculator:getStringWidth(newLineIndent)
  self.stringWidthCalculator:reset()

  self.maximumLineWidth = self.maximumLineWidth - newLineIndentWidth
  self.rowDimensionsCalculator:setMinimumRowLength(1 + #newLineIndent)

end

---
-- Initializes the width for the next row.
--
function RowBuilder:initializeNextRowWidth()

  if (self.currentRowStartPosition < self.lastParsedPosition) then

    self.stringWidthCalculator:setWidth(
      self.widthCacher:getWidthBetween(self.currentRowStartPosition, self.lastParsedPosition)
    )

  end

end


-- When RowBuilder() is called, call the __construct method
setmetatable(RowBuilder, {__call = RowBuilder.__construct})


return RowBuilder
