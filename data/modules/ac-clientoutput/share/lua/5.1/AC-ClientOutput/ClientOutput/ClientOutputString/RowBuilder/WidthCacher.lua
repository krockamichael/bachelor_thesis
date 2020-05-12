---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

---
-- Handles caching of widths.
--
-- @type WidthCacher
--
local WidthCacher = {}


---
-- The saved widths at certain positions in the target string
-- The table is in the format { [position] = width, ... }
--
-- @tfield table cachedPositionWidths
--
WidthCacher.cachedPositionWidths = nil

---
-- The history of cached total widths
-- This table is in the format { { ["position"] = int, ["width"] = int }, ... }
--
-- @tfield table totalWidthHistory
--
WidthCacher.totalWidthHistory = nil

---
-- The maximum size for the totalWidthHistory
--
-- @tfield int maximumTotalWidthHistorySize
--
WidthCacher.maximumTotalWidthHistorySize = 0

---
-- Stores whether the maximum total width history size is reached
--
-- @tfield bool maximumTotalWidthHistorySizeReached
--
WidthCacher.maximumTotalWidthHistorySizeReached = nil


-- Metamethods

---
-- WidthCacher constructor.
-- This is the __call metamethod.
--
-- @tparam int _maximumTotalWidthHistorySize The maximum size for the totalWidthHistory
--
-- @treturn WidthCacher The WidthCacher instance
--
function WidthCacher:__construct(_maximumTotalWidthHistorySize)
  local instance = setmetatable({}, {__index = WidthCacher})
  instance.maximumTotalWidthHistorySize = _maximumTotalWidthHistorySize
  instance:reset()

  return instance
end


-- Public Methods

---
-- Adds a total width to the cache.
--
-- @tparam int _characterNumber The character number
-- @tparam int _width The width at the character number
-- @tparam bool _isCachePostion True if this position must be cached separately
--
function WidthCacher:cacheTotalWidth(_characterNumber, _width, _isCachePostion)

  if (_isCachePostion) then
    self.cachedPositionWidths[_characterNumber] = _width
  end

  self:addWidthToTotalWidthHistory(_characterNumber, _width)

end

---
-- Returns the width between two character positions.
-- The passed positions must be ones for which a cached width exists.
--
-- @tparam int _startCharacterNumber The start position
-- @tparam int _endCharacterNumber The end position
--
-- @treturn int The width between the positions
--
function WidthCacher:getWidthBetween(_startCharacterNumber, _endCharacterNumber)
  return self:getWidthAtPosition(_endCharacterNumber) - self:getWidthAtPosition(_startCharacterNumber)
end

---
-- Resets the cache.
--
function WidthCacher:reset()
  self.cachedPositionWidths = {}
  self.totalWidthHistory = {}
  self.maximumTotalWidthHistorySizeReached = false
end


-- Private Methods

---
-- Adds a width to the total width history.
--
-- @tparam int _characterNumber The character number
-- @tparam int _width The width at the character number
--
function WidthCacher:addWidthToTotalWidthHistory(_characterNumber, _width)

  -- Remove the first entry from the history if required
  if (self.maximumTotalWidthHistorySizeReached) then
    table.remove(self.totalWidthHistory, 1)
  end

  -- Add the width to the history
  table.insert(self.totalWidthHistory, { position = _characterNumber, width = _width })

  -- Check if the maximum history size is reached
  if (not self.maximumTotalWidthHistorySizeReached and
      #self.totalWidthHistory == self.maximumTotalWidthHistorySize) then
    self.maximumTotalWidthHistorySizeReached = true
  end

end

---
-- Returns the cached width at a specified position.
-- Will return nil if no width was cached for that position.
--
-- @tparam int _position The position
--
-- @treturn int|nil The width at the position
--
function WidthCacher:getWidthAtPosition(_position)

  if (_position == 1) then
    return 0
  end

  local cachedPositionWidth = self.cachedPositionWidths[_position]
  if (cachedPositionWidth == nil) then

    -- Search the total width history for the position
    for i = #self.totalWidthHistory, 1, -1 do
      if (self.totalWidthHistory[i]["position"] == _position) then
        return self.totalWidthHistory[i]["width"]
      end
    end

  else
    return cachedPositionWidth
  end

end


-- When WidthCacher() is called, call the __construct method
setmetatable(WidthCacher, {__call = WidthCacher.__construct})


return WidthCacher
