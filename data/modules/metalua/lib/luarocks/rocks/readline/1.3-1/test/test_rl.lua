#! /usr/bin/lua
local M = require 'readline'
require 'DataDumper'

--------------------------- infrastructure -----------------------
local eps = .000000001
function equal(x, y)  -- unused here
    if #x ~= #y then return false end
    local i; for i in pairs(x) do
        if math.abs(x[i]-y[i]) > eps then return false end
    end
    return true
end
-- use Test::Simple tests => 6;
local Test = 73 ; local i_test = 0; local Failed = 0;
function ok(b,s)
    i_test = i_test + 1
    if b then
        io.write('ok '..i_test..' - '..s.."\n")
		return true
    else
        io.write('not ok '..i_test..' - '..s.."\n")
        Failed = Failed + 1
		return false
    end
end

local function qw(s)  -- t = qw([[ foo  bar  baz ]])
    local t = {}
	for x in s:gmatch("([-%s]+)") do t[#t+1] = x end
	return t
end

local function uname_minus_s()
    local pipe = assert(io.popen('uname -s'))
    local uname_output = pipe:read('*all')
    pipe:close()
    return string.gsub(uname_output, '%s$', '')
end

-- strict.lua    checks uses of undeclared global variables
-- All global variables must be 'declared' through a regular assignment
-- (even assigning nil will do) in a main chunk before being used
-- anywhere or assigned to inside a function.
local mt = getmetatable(_G)
if mt == nil then
  mt = {}
  setmetatable(_G, mt)
end
mt.__declared = {}
mt.__newindex = function (t, n, v)
  if not mt.__declared[n] then
    local w = debug.getinfo(2, "S").what
    if w ~= "main" and w ~= "C" then
      error("assign to undeclared variable '"..n.."'", 2)
    end
    mt.__declared[n] = true
  end
  rawset(t, n, v)
end
mt.__index = function (t, n)
  if not mt.__declared[n] and debug.getinfo(2, "S").what ~= "C" then
    error("variable '"..n.."' is not declared", 2)
  end
  return rawget(t, n)
end


----------------------- here we go... -------------------------

print('Testing readline.lua '..M.Version..', '..M.VersionDate..
 ' on '..uname_minus_s())

if not ok(type(M) == 'table', 'type of M is table') then
	print('type was '..type(M))
end

-- for k,v in pairs(M) do print(k,tostring(v)) end
local filename = '/tmp/test_rl_history'
M.set_options{histfile=filename}
os.remove(filename)

print('Please make all answers longer than two characters !')
local s1 = M.readline('Please enter something: ')
if not ok(type(s1)=='string', "readline returned "..s1) then
	print('xc='..tostring(xc)..' xv='..tostring(xv))
end
local s2 = M.readline('this time Up-arrow should work: ')
local s3 = M.readline('enter a filename and test Tab-completion: ')
local save = M.set_options{completion=false}
local s4 = M.readline('now Tab-completion should be disabled: ')
M.set_options(save)
local s5 = M.readline('now it should be re-enabled :-) ')
M.set_options{auto_add=false}
local s6 = M.readline('this answer should not get added into the history: ')
M.set_options(save)
local s7 = M.readline('now it should be re-enabled :-) ')
M.save_history()

print('Now checking the saved histfile:')
local F = assert(io.open(filename))
local lines = {}
for line in F:lines() do lines[#lines+1] = line end
F:close()
if not ok(lines[1] == s1, 'line 1 was '..s1) then
	print('lines[1]='..tostring(lines[1])..' s1='..tostring(s1))
end
if not ok(lines[2] == s2, 'line 2 was '..s2) then
	print('lines[2]='..tostring(lines[2])..' s2='..tostring(s2))
end
if not ok(lines[3] == s3, 'line 3 was '..s3) then
	print('lines[3]='..tostring(lines[3])..' s3='..tostring(s3))
end
if not ok(lines[4] == s4, 'line 4 was '..s4) then
	print('lines[4]='..tostring(lines[4])..' s4='..tostring(s4))
end
if not ok(lines[5] == s5, 'line 5 was '..s5) then
	print('lines[5]='..tostring(lines[5])..' s5='..tostring(s5))
end
if not ok(lines[6] == s7, 'line 6 was '..s7) then
	print('lines[6]='..tostring(lines[6])..' s7='..tostring(s7))
end
os.remove(filename)

-- print('strerror(2) = '..M.strerror(2))

if Failed == 0 then
	print('Passed all '..i_test..' tests :-)')
else
	print('Failed '..Failed..' tests out of '..i_test)
end

os.exit()
