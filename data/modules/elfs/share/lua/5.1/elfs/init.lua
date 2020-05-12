local socket = require("socket")
module("elfs", package.seeall)
math.randomseed(socket.gettime() * 10000)
local names = require("elfs.names")
local moves = require("elfs.moves")
local getElement
getElement = function(list)
  return list[math.random(#list)]:lower():gsub("-", "")
end
GenName = function()
  return tostring(getElement(moves)) .. "-" .. tostring(getElement(moves)) .. "-" .. tostring(getElement(names))
end
