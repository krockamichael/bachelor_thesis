---
-- @author wesen
-- @copyright 2018-2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

---
-- Returns the output rows for a ClientOutputTable.
--
-- @type ClientOutputTableRenderer
--
local ClientOutputTableRenderer = {}


---
-- The parent ClientOutputTable
--
-- @tfield ClientOutputTable clientOutputTable
--
ClientOutputTableRenderer.parentClientOutputTable = nil


-- Metamethods

---
-- ClientOutputTableRenderer constructor.
-- This is the __call metamethod.
--
-- @tparam ClientOutputTable _parentClientOutputTable The parent ClientOutputTable
--
-- @treturn ClientOutputTableRenderer The ClientOutputTableRenderer instance
--
function ClientOutputTableRenderer:__construct(_parentClientOutputTable)
  local instance = setmetatable({}, {__index = ClientOutputTableRenderer})
  instance.parentClientOutputTable = _parentClientOutputTable

  return instance
end


-- Public Methods

---
-- Returns the row output strings for the parent ClientOutputTable.
--
-- @tparam int|nil _padTabNumber The pad tab number (optional)
--
-- @treturn string[]|ClientOutputString[] The row output strings
--
function ClientOutputTableRenderer:getOutputRows(_padTabNumber)

  self:calculateNumbersOfTabsPerColumn()

  -- Replace the sub tables with the result of getRowStrings()
  local outputTable = self:convertSubTablesToRows(_padTabNumber)

  -- Merge the sub rows into the main table
  outputTable = self:mergeSubRows(outputTable)

  -- Add the tabs to the fields
  outputTable = self:addTabsToFields(outputTable, _padTabNumber)

  return self:generateRowStrings(outputTable, _padTabNumber)

end


-- Private Methods

---
-- Calculates the numbers of tabs to use per column.
-- The result is saved in the numbersOfTabsPerColumn attribute.
--
function ClientOutputTableRenderer:calculateNumbersOfTabsPerColumn()

  local numberOfColumns = self.parentClientOutputTable:getNumberOfColumns()
  local remainingNumberOfTabs = self.parentClientOutputTable:getMaximumNumberOfTabs()

  self.numbersOfTabsPerColumn = {}
  for x = 1, numberOfColumns, 1 do

    local numberOfRequiredTabsForColumn = self.parentClientOutputTable:getNumberOfRequiredTabsForColumn(x)

    self.numbersOfTabsPerColumn[x] = numberOfRequiredTabsForColumn
    remainingNumberOfTabs = remainingNumberOfTabs - numberOfRequiredTabsForColumn

  end

  if (remainingNumberOfTabs < 0) then

    local minimumNumbersOfTabsPerColumn = {}
    for x = 1, numberOfColumns, 1 do
      minimumNumbersOfTabsPerColumn[x] = self.parentClientOutputTable:getMinimumNumberOfRequiredTabsForColumn(x)
    end

    while (remainingNumberOfTabs < 0) do

      -- Find the column with the biggest distance to the minimum number of required tabs
      local shrinkColumnNumber
      local maximumNumberOfRemovableTabs = 0
      for x = 1, numberOfColumns, 1 do

        local numberOfRemovableTabs = self.numbersOfTabsPerColumn[x] - minimumNumbersOfTabsPerColumn[x]
        if (numberOfRemovableTabs > maximumNumberOfRemovableTabs) then
          maximumNumberOfRemovableTabs = numberOfRemovableTabs
          shrinkColumnNumber = x
        end

      end

      if (shrinkColumnNumber == nil) then
        break
      else
        self.numbersOfTabsPerColumn[shrinkColumnNumber] = self.numbersOfTabsPerColumn[shrinkColumnNumber] - 1
        remainingNumberOfTabs = remainingNumberOfTabs + 1
      end

    end

  end

end

---
-- Replaces sub tables by the row output strings of the sub table.
--
-- @tparam int|nil _padTabNumber The pad tab number (optional)
--
-- @treturn table The table with converted sub tables
--
function ClientOutputTableRenderer:convertSubTablesToRows(_padTabNumber)

  local outputTable = {}

  local numberOfColumns = self.parentClientOutputTable:getNumberOfColumns()
  local padTabNumberIsDefined = (_padTabNumber ~= nil)
  for y, tableRow in ipairs(self.parentClientOutputTable:getRows()) do

    outputTable[y] = {}
    for x, tableField in ipairs(tableRow) do

      tableField:changeMaximumNumberOfTabs(self.numbersOfTabsPerColumn[x])
      if (padTabNumberIsDefined or x < numberOfColumns) then
        outputTable[y][x] = tableField:getOutputRowsPaddedWithTabs(self.numbersOfTabsPerColumn[x])
      else
        outputTable[y][x] = tableField:getOutputRows()
      end

    end

  end

  return outputTable

end

---
-- Combines the rows of the sub tables with the total table.
--
-- @tparam table _outputTable The output table with converted sub tables
--
-- @treturn string[][] The table with combined sub table rows
--
function ClientOutputTableRenderer:mergeSubRows(_outputTable)

  local outputTable = {}
  local mainTableInsertIndex = 1

  for _, tableRow in ipairs(_outputTable) do

    outputTable[mainTableInsertIndex] = {}

    local maximumMainTableInsertIndexForTable = mainTableInsertIndex
    for x, tableField in ipairs(tableRow) do

      if (type(tableField) == "table") then
        -- The field contains sub rows
        local mainTableInsertIndexForTable = mainTableInsertIndex
        local isFirstSubRow = true

        for _, subRow in ipairs(tableField) do

          if (isFirstSubRow) then
            isFirstSubRow = false
          else
            mainTableInsertIndexForTable = mainTableInsertIndexForTable + 1
          end

          -- Create the additional row if it doesn't exist
          if (not outputTable[mainTableInsertIndexForTable]) then
            outputTable[mainTableInsertIndexForTable] = {}
          end

          outputTable[mainTableInsertIndexForTable][x] = subRow

          if (mainTableInsertIndexForTable > maximumMainTableInsertIndexForTable) then
            maximumMainTableInsertIndexForTable = mainTableInsertIndexForTable
          end

        end

      else
        outputTable[mainTableInsertIndex][x] = tableField
      end
    end

    mainTableInsertIndex = maximumMainTableInsertIndexForTable + 1

  end

  return outputTable

end

---
-- Adds the tabs to all fields of the table.
--
-- @tparam table _outputTable The output table
-- @tparam int|nil _padTabNumber The pad tab number (optional)
--
-- @treturn table The output table with added tabs
--
function ClientOutputTableRenderer:addTabsToFields(_outputTable, _padTabNumber)

  local outputTable = {}
  local padTabNumberIsDefined = (_padTabNumber ~= nil)

  if (_outputTable) then

    outputTable = _outputTable

    local numberOfColumns = #outputTable[1]
    for x = 1, numberOfColumns, 1 do

      local numberOfTabsForColumn = self.numbersOfTabsPerColumn[x]
      for y, tableRow in ipairs(outputTable) do

        local field = tableRow[x]

        if (field == nil) then
          if (padTabNumberIsDefined or x < numberOfColumns) then
            field = string.rep("\t", numberOfTabsForColumn)
          else
            field = ""
          end
        end

        outputTable[y][x] = field

      end
    end

  end

  return outputTable

end

---
-- Generates the row strings from a output table.
-- The output table must be one dimensional and may not contain empty fields.
--
-- @tparam table[] _outputTable The output table
-- @tparam int|nil _padTabNumber The pad tab number (optional)
--
-- @treturn string[]|ClientOutputString[] The output rows
--
function ClientOutputTableRenderer:generateRowStrings(_outputTable, _padTabNumber)

  local rowOutputStrings = {}
  for y, row in ipairs(_outputTable) do
    rowOutputStrings[y] = table.concat(row, "")
  end

  return rowOutputStrings

end


-- When ClientOutputTableRenderer() is called, call the __construct method
setmetatable(ClientOutputTableRenderer, {__call = ClientOutputTableRenderer.__construct})


return ClientOutputTableRenderer
