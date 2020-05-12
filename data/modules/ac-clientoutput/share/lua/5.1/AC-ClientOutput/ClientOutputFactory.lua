---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local ClientOutputString = require("AC-ClientOutput/ClientOutput/ClientOutputString/ClientOutputString")
local ClientOutputTable = require("AC-ClientOutput/ClientOutput/ClientOutputTable/ClientOutputTable")
local SymbolWidthLoader = require("AC-ClientOutput/ClientOutput/Util/SymbolWidthLoader")
local TabStopCalculator = require("AC-ClientOutput/ClientOutput/Util/TabStopCalculator")

---
-- Provides static methods to configure a font config and to create ClientOutputString and ClientOutputTable instances.
--
-- @type ClientOutputFactory
--
local ClientOutputFactory = {}


---
-- The ClientOutputFactory instance that will be returned by the getInstance method
--
-- @tfield ClientOutputFactory instance
--
ClientOutputFactory.instance = nil

---
-- The symbol width loader for the ClientOutputString and ClientOutputTable instances
--
-- @tfield SymbolWidthLoader symbolWidthLoader
--
ClientOutputFactory.symbolWidthLoader = nil

---
-- The tab stop calculator for the ClientOutputString and ClientOutputTable instances
--
-- @tfield TabStopCalculator tabStopCalculator
--
ClientOutputFactory.tabStopCalculator = nil

---
-- The maximum line width in 3x pixels
--
-- @tfield int maximumLineWidth
--
ClientOutputFactory.maximumLineWidth = 3900

---
-- The default configuration for ClientOutputString's and ClientOutputTable's
-- These values can be overwritten by the config section in each template
--
-- @tfield mixed[] defaultConfiguration
--
ClientOutputFactory.defaultConfiguration = nil


-- Metamethods

---
-- ClientOutputFactory constructor.
-- This is the __call metamethod.
--
-- @treturn ClientOutputFactory The ClientOutputFactory instance
--
function ClientOutputFactory:__construct()
  local instance = setmetatable({}, {__index = ClientOutputFactory})
  instance:changeFontConfig("FontDefault")
  instance.defaultConfiguration = {
    newLineIndent = "",
    lineSplitCharacters = " "
  }

  return instance
end


-- Public Methods

---
-- Returns a ClientOutputFactory instance.
-- This will return the same instance on subsequent calls.
--
-- @treturn ClientOutputFactory The ClientOutputFactory instance
--
function ClientOutputFactory.getInstance()

  if (ClientOutputFactory.instance == nil) then
    ClientOutputFactory.instance = ClientOutputFactory()
  end

  return ClientOutputFactory.instance

end

---
-- Configures this ClientOutputFactory.
--
-- @tparam table _configuration The configuration
--
function ClientOutputFactory:configure(_configuration)

  if (_configuration["fontConfigFileName"] ~= nil) then
    self:changeFontConfig(_configuration["fontConfigFileName"])
  end

  if (_configuration["maximumLineWidth"] ~= nil) then
    self.maximumLineWidth = tonumber(_configuration["maximumLineWidth"])
  end

  if (_configuration["newLineIndent"] ~= nil) then
    self.defaultConfiguration["newLineIndent"] = _configuration["newLineIndent"]
  end

  if (_configuration["lineSplitCharacters"] ~= nil) then
    self.defaultConfiguration["lineSplitCharacters"] = _configuration["lineSplitCharacters"]
  end

end


---
-- Creates and returns a ClientOutputString from a string.
--
-- @tparam string _string The string
-- @tparam table _configuration The configuration for the ClientOutputString (optional)
--
-- @treturn ClientOutputString The ClientOutputString for the string
--
function ClientOutputFactory:getClientOutputString(_string, _configuration)

  local clientOutputString = ClientOutputString(
    self.symbolWidthLoader, self.tabStopCalculator, self.maximumLineWidth
  )

  clientOutputString:configure(self.defaultConfiguration)
  if (_configuration) then
    clientOutputString:configure(_configuration)
  end

  clientOutputString:parse(_string)

  return clientOutputString

end

---
-- Creates and returns a ClientOutputTable from a table.
--
-- @tparam table _table The table
-- @tparam table _configuration The configuration for the ClientOutputTable (optional)
--
-- @treturn ClientOutputTable The ClientOutputTable for the table
--
function ClientOutputFactory:getClientOutputTable(_table, _configuration)

  local clientOutputTable = ClientOutputTable(
    self.symbolWidthLoader, self.tabStopCalculator, self.maximumLineWidth
  )

  clientOutputTable:configure(self.defaultConfiguration)
  if (_configuration) then
    clientOutputTable:configure(_configuration)
  end

  clientOutputTable:parse(_table)

  return clientOutputTable

end


-- Private Methods

---
-- Reinitializes the symbol width loader and the tab stop calculator to use a new font config.
--
-- @tparam string _fontConfigFileName The font config file name
--
function ClientOutputFactory:changeFontConfig(_fontConfigFileName)
  self.symbolWidthLoader = SymbolWidthLoader(_fontConfigFileName)
  self.tabStopCalculator = TabStopCalculator(self.symbolWidthLoader:getCharacterWidth("\t"))
end


-- When ClientOutputFactory() is called, call the __construct method
setmetatable(ClientOutputFactory, {__call = ClientOutputFactory.__construct})


return ClientOutputFactory
