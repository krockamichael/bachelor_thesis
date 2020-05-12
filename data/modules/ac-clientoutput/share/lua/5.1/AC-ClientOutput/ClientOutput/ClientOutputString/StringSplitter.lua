---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local StringParser = require("AC-ClientOutput/ClientOutput/ClientOutputString/StringParser/StringParser")
local RowBuilder = require("AC-ClientOutput/ClientOutput/ClientOutputString/RowBuilder/RowBuilder")

---
-- Provides methods to split a string into rows.
--
-- @type StringSplitter
--
local StringSplitter = {}


---
-- The parent ClientOutputString
--
-- @tfield ClientOutputString parentClientOutputString
--
StringSplitter.parentClientOutputString = nil

---
-- The string parser
--
-- @tfield StringParser parser
--
StringSplitter.parser = nil

---
-- The current parsed string
--
-- @tfield ParsedString parsedString
--
StringSplitter.parsedString = nil

---
-- The row builder
--
-- @tfield RowBuilder rowBuilder
--
StringSplitter.rowBuilder = nil


-- Metamethods

---
-- StringSplitter constructor.
-- This is the __call metamethod.
--
-- @tparam ClientOutputString _parentClientOutputString The parent ClientOutputString
-- @tparam SymbolWidthLoader _symbolWidthLoader The symbol width loader
-- @tparam TabStopCalculator _tabStopCalculator The tab stop calculator
--
-- @treturn StringSplitter The StringSplitter instance
--
function StringSplitter:__construct(_parentClientOutputString, _symbolWidthLoader, _tabStopCalculator)

  local instance = setmetatable({}, {__index = StringSplitter})
  instance.parentClientOutputString = _parentClientOutputString
  instance.parser = StringParser()
  instance.rowBuilder = RowBuilder(_parentClientOutputString, _symbolWidthLoader, _tabStopCalculator)

  return instance

end


-- Public Methods

---
-- Splits a string into rows.
--
-- @tparam int|nil _padTabNumber The tab number until which the rows shall be padded with tabs (optional)
--
-- @treturn string[] The rows
--
function StringSplitter:getRows(_padTabNumber)

  local parsedString = self:getParsedParentClientOutputString()
  self.rowBuilder:initialize(parsedString)

  local characterNumber = 1
  local currentRowStartPosition = 1

  local rowStrings = {}
  for character in parsedString:getString():gmatch(".") do
    if (characterNumber >= currentRowStartPosition) then

      if (self.rowBuilder:isMaximumLineWidthReached()) then
        local rowString = self.rowBuilder:buildNextRow(false, _padTabNumber)

        table.insert(rowStrings, rowString)
        currentRowStartPosition = self.rowBuilder:getCurrentRowStartPosition()
      end

      self.rowBuilder:parseCharacter(characterNumber, character)

    end

    characterNumber = characterNumber + 1
  end

  -- Add the final row string if required
  if (currentRowStartPosition ~= nil) then
    local rowString = self.rowBuilder:buildNextRow(true, _padTabNumber)
    table.insert(rowStrings, rowString)
  end

  self.rowBuilder:reset()

  return rowStrings

end


-- Private Methods

---
-- Returns the parsed parent ClientOutputString.
--
-- @treturn ParsedString The parsed parent ClientOutputString
--
function StringSplitter:getParsedParentClientOutputString()

  if (not self.parsedString or
      self.parsedString:getLineSplitCharacters() ~= self.parentClientOutputString:getLineSplitCharacters() or
      self.parsedString:getString() ~= self.parentClientOutputString:getString()) then

    -- The cached parsed string is not up to date, reparse the parent ClientOutputString
    self.parser:reset()
    self.parser:setLineSplitCharacters(self.parentClientOutputString:getLineSplitCharacters())
    self.parsedString = self.parser:parse(self.parentClientOutputString:getString())

  end

  return self.parsedString

end


-- When StringSplitter() is called, call the __construct method
setmetatable(StringSplitter, {__call = StringSplitter.__construct})


return StringSplitter
