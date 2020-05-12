
-- Try to load bit library
local bit
local have_bit = pcall(function() bit = require "bit" end)

-- If we have the bit library, use that, otherwise, use built-in operators
-- (which are only available in Lua 5.3)
if have_bit then
  return {
    band = bit.band,
    bor = bit.bor,
    lshift = bit.lshift,
    rshift = bit.rshift,
    tohex = bit.tohex
  }
else
  return require("amqp.bitnative")
end

