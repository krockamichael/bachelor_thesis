---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local BaseClientOutput = require("AC-ClientOutput/ClientOutput/BaseClientOutput")
local StringSplitter = require("AC-ClientOutput/ClientOutput/ClientOutputString/StringSplitter")
local StringWidthCalculator = require("AC-ClientOutput/ClientOutput/ClientOutputString/StringWidthCalculator")

---
-- Represents a output string for the console in the players games.
-- Allows to split a string into rows based on a specified width.
--
-- @type ClientOutputString
--
local ClientOutputString = {}


---
-- The raw string
-- The text may not contain the special character "\n"
--
-- @tfield string string
--
ClientOutputString.string = nil

--
-- The client output string splitter
--
-- @tfield ClientOutputStringSplitter splitter
--
ClientOutputString.splitter = nil


-- Metamethods

---
-- ClientOutputString constructor.
-- This is the __call metamethod.
--
-- @tparam SymbolWidthLoader _symbolWidthLoader The symbol width loader
-- @tparam TabStopCalculator _tabStopCalculator The tab stop calculator
-- @tparam int _maximumLineWidth The maximum line width
--
-- @treturn ClientOutputString The ClientOutputString instance
--
function ClientOutputString:__construct(_symbolWidthLoader, _tabStopCalculator, _maximumLineWidth)

  local instance = BaseClientOutput(_symbolWidthLoader, _tabStopCalculator, _maximumLineWidth)
  setmetatable(instance, {__index = ClientOutputString})

  instance.splitter = StringSplitter(instance, _symbolWidthLoader, _tabStopCalculator)

  return instance

end


-- Getters and Setters

---
-- Returns the target string.
--
-- @treturn string The target string
--
function ClientOutputString:getString()
  return self.string
end


-- Public Methods

---
-- Parses a string into this ClientOutputString.
--
-- @tparam string _string The string to parse
--
function ClientOutputString:parse(_string)
  self.string = _string:gsub("\n", "")
end

---
-- Returns the number of tabs that this client output's content requires.
--
-- @treturn int The number of required tabs
--
function ClientOutputString:getNumberOfRequiredTabs()
  local stringWidthCalculator = StringWidthCalculator(self.symbolWidthLoader, self.tabStopCalculator)
  return self.tabStopCalculator:getNextTabStopNumber(stringWidthCalculator:getStringWidth(self.string))
end

---
-- Returns the minimum number of tabs that this client output's content requires.
--
-- @treturn int The minimum number of required tabs
--
function ClientOutputString:getMinimumNumberOfRequiredTabs()
  return 1
end

---
-- Returns the output rows to display this client output's contents.
--
-- @treturn string[] The output rows
--
function ClientOutputString:getOutputRows()
  return self.splitter:getRows()
end

---
-- Returns the output rows padded with tabs until a specified tab number.
--
-- @tparam int _tabNumber The tab number
--
-- @treturn string[] The output rows padded with tabs
--
function ClientOutputString:getOutputRowsPaddedWithTabs(_tabNumber)
  return self.splitter:getRows(_tabNumber)
end


setmetatable(
  ClientOutputString,
  {
    -- ClientOutputString inherits methods and attributes from BaseClientOutput
    __index = BaseClientOutput,

    -- When ClientOutputString() is called, call the __construct method
    __call = ClientOutputString.__construct
  }
)


return ClientOutputString
