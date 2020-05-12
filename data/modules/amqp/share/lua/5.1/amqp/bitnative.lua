
-- Bit operations implemented using native operators.
return {
  band = function(a,b) return a & b end,
  bor = function(a,b) return a | b end,
  lshift = function(a,b) return a << b end,
  rshift = function(a,b) return a >> b end,
  tohex = function(a) return string.format("%x", a) end
}
