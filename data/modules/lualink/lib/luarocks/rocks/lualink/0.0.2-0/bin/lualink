#!/usr/bin/env lua

local function show_usage()
    print("Usage: lualink [-o OUTPUT_FILE] main=FILE [-mMODULE=FILE]... [-rRESOURCEPATH=FILE]...")
end

local out_name = nil
local module_map= {}
local resource_map= {}

local i = 1
while true do
    if arg[i] == nil then
        break
    elseif arg[i] == "-o" then
        if out_name == nil then
            out_name = arg[i + 1]
            i = i + 1
        else
            show_usage()
            os.exit(1)
        end
    else
        modname, filename = arg[i]:match("^-m([^=]*)=([^=]*)$")
        if modname ~= nil and filename ~= nil then
            module_map[modname] = filename
        else
            respath, filename = arg[i]:match("^-r([^=]*)=([^=]*)$")
            if respath == nil or filename == nil then
                show_usage()
                os.exit(1)
            else
                resource_map[respath] = filename
            end
        end
    end

    i = i + 1
end

if module_map.main == nil then
    show_usage()
    os.exit(1)
end

if out_name == nil then
    out_name = "a.lua"
end

local out = io.open(out_name, "w")

out:write("package.resources = {}\n")

for modulename, filename in pairs(module_map) do
    result, err = loadfile(filename, "t")
    if result == nil then
        print(err)
        os.exit(1)
    end

    local f, err = io.open(filename, "r")
    if f == nil then
        print("error: " .. err)
        os.exit(1)
    end

    out:write(string.format("package.preload['%s'] = function()\n", modulename))
    local firstline = f:read()
    if firstline:sub(1, 2) ~= "#!" then
        out:write(firstline .. "\n")
    end
    out:write(f:read("*all"))
    out:write("\nend\n")

    f:close()
end

for resourcepath, filename in pairs(module_map) do
    local f, err = io.open(filename, "r")
    if f == nil then
        print("error: " .. err)
        os.exit(1)
    end

    out:write(string.format("package.resources['%s'] =[[", resourcepath))
    out:write(f:read("*all"))
    out:write("]]")

    f:close()
end

out:write("require('main')\n")

out:close()
