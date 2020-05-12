local class = require 'stuart.class'

local Partition = class.new()

function Partition:_init(data, index)
  self.data = data or {}
  self.index = index or 0
end

function Partition:_count()
  return #self.data
end

function Partition:_flatten()
  local moses = require 'moses'
  self.data = moses.flatten(self.data)
  return self
end

function Partition:_flattenValues()
  local moses = require 'moses'
  self.data = moses.reduce(self.data, function(r, e)
    local x = e[2]
    if moses.isString(x) then
      local t = {}
      x:gsub('.', function(c) t[#t+1] = c end)
      x = t
    end
    moses.map(x, function(v)
      table.insert(r, {e[1], v})
    end)
    return r
  end, {})
  return self
end

function Partition:iterator()
  local i = 0
  return function()
    i = i + 1
    return self.data[i]
  end
end

return Partition
