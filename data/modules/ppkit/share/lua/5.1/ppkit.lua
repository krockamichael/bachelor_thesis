-- ppkit | 22.06.2
-- By daelvn
-- Preprocessor kit

--# Namespace #--
local ppkit = {}
ppkit.cl    = {}

--# Libraries #--
local lobject = require "lobject"
local ansi    = require "ansicolors"
local Class   = lobject.class

--# Utils #--
local function p (s) print (ansi (s)) end
local function v (s) if ppkit.cl.v then print (ansi (s)) end end

--# Create compiler class #--
ppkit.compiler = Class "PPKitCompiler" (function (argl)
  if type (argl.spec) ~= "table" then return "PPKitCompiler: spec must be a table!" end
  -- Object
  local object = {}
  object.mode  = {}
  -- Sanitize specification
  argl.spec.name    = argl.spec.name    or "Unknown"
  argl.spec.version = argl.spec.version or "1"
  argl.spec.defines = argl.spec.defines or {}
  for idef,def in pairs (argl.spec.defines) do
    def.name      = def.name      or "unknown.ppkit"
    def.condition = def.condition or ""
    def.capture   = def.capture   or {}
    def.replace   = def.replace   or {}
    def.mode      = def.mode      or {}
    def.process   = def.process   or {}
  end
  object.spec = argl.spec
  -- Return
  return object
end)

--# Add spec compiler #--
function ppkit.compiler:compile (input)
  local spec   = self.spec
  local output = {}
  p ("%{bright blue}ppkit%{reset} for " .. spec.name .. " " .. spec.version)
  v "======================================================================"
  v "%{bright blue}::%{reset} Iterating lines"
  for index, line in pairs (input) do
    v "----------------------------------------------------------------------"
    v ("-- Using line: " .. line)
    v "%{bright blue}::%{reset} Starting inner specification iterator"
    for idefinition, definition in pairs (spec.defines) do
      v ("%{bright cyan}==%{reset} Parsing definition%{bright} " .. definition.name)
      v ("   %{bright}Condition:%{reset} " .. definition.condition)
      -- Check if matches condition
      if line:match (definition.condition) then
        v "     Line matches!"
      else
        v "     Line does not match!"
        goto nextISI
      end
      -- Check if it matches mode conditions
      for kmodech, modech in pairs (definition.mode) do
        if kmodech:match "^c" then
          v ("   %{bright}Mode condition:%{reset} " .. modech)
          local cond
          v ("     %{bright}Type:%{reset}" .. type (self.mode [modech]))
          if   type (self.mode [modech]) == "number" then cond = self.mode [modech] > 0
          else cond = self.mode [modech]
          end
          if cond then
            v "     Condition met!"
          else
            v "     Condition not met!"
            goto nextISI
          end
        end
      end
      -- Create captures
      v "%{bright cyan}==%{reset} Creating captures"
      local groupl = {}
      for ipattern, pattern in pairs (definition.capture) do
				v ("   %{bright}Pattern " .. tonumber (ipattern) .. ": " .. pattern)
        v ("     Should match: " .. (line:match (pattern) or "None"))
        if ipattern < 0 then
            v "     Single match mode!"
            local capture   = line:match (pattern)
            if capture then
              --local aipattern = math.abs (ipattern)
              v ("     Captured: %{bright} " .. capture)
              groupl [ipattern] = groupl [ipattern] or {} -- See comment below
              capture = capture:gsub ("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
              v ("     Saving capture:%{bright} " .. capture)
              table.insert (groupl [ipattern], line:match (pattern)) -- Not using aipattern is intentional here
          end
        else
          for capture in line:gmatch (pattern) do
            v ("     Captured:%{bright} " .. capture)
            groupl [ipattern] = groupl [ipattern] or {}
            capture = capture:gsub ("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
            v ("     Saving capture:%{bright} " .. capture)
            table.insert (groupl [ipattern], capture)
          end
        end
      end
      -- Do replacements
      v "%{bright cyan}==%{reset} Replacing captures"
      for igroup, group in pairs (groupl) do
        v ("   Group%{bright} " .. tostring (igroup))
        v ("     Replace pattern for group:%{bright} " .. definition.replace [igroup])
        for icapture, capture in ipairs (group) do
            v ("     Capture:%{bright} " .. capture)
            line = line:gsub  (--[[capture]]definition.capture [igroup], definition.replace [igroup])
        end
      end
      -- Change modes
      v "%{bright cyan}==%{reset} Changing modes"
      for kmodech, modech in pairs (definition.mode) do
        if kmodech:match "^a" then
          v ("%{bright green} + %{reset}" .. modech)
          self.mode [modech] = true
        elseif kmodech:match "^r" then
          v ("%{bright green} - %{reset}" .. modech)
          self.mode [modech] = false
        elseif kmodech:match "^i" then
          if type (self.mode [modech]) ~= "number" then self.mode [modech] = 0 end
          v ("%{bright green} ^ %{reset}" .. modech .. ": " .. tostring (self.mode [modech]+1))
          self.mode [modech] = self.mode [modech] + 1
        elseif kmodech:match "^d" then
          if type (self.mode [modech]) ~= "number" then self.mode [modech] = 0 end
          v ("%{bright green} v %{reset}" .. modech .. ": " .. tostring (self.mode[modech]-1))
          self.mode [modech] = self.mode [modech] - 1
        elseif kmodech:match "^t" then
          v "%{bright green} ! %{reset}Stopping mode processing"
          break
        elseif kmodech:match "^c" then
          v ("%{bright green} @ %{reset}" .. modech)
        else
          v ("%{bright green} ? %{reset}" .. modech)
        end
      end
      if ppkit.cl.dump then
        v "%{bright blue}::%{reset} Dumping modes"
        for kmode, mode in pairs (self.mode) do
          v (" - " .. kmode .. ": " .. tostring (mode))
        end
      end
      if ppkit.cl.wait then
        p "%{bright red}Press Enter to continue execution"
        local _ = io.read ()
      end
      ::nextISI::
    end
    --::nextLine::
    v "%{bright blue}::%{reset} Exited ISI"
    if line == "#@ppkit.noprint" then v ("-- Not printing line%{bright} " .. tostring (index))
    else v ("-- Printing line%{bright} " .. tostring (index))
      table.insert (output, line)
    end
  end
  v "%{bright blue}::%{reset} Exited line iterator"
  return output
end

--# Return #--
return ppkit
