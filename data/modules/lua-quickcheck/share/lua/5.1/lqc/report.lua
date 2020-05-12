
--- Helper module for reporting test results to the user.
-- @module lqc.report
-- @alias lib

local map = require 'lqc.helpers.map'

local write = io.write
local ipairs = ipairs

-- Variables for reporting statistics after test run is over.
local passed_amount = 0
local failed_amount = 0
local skipped_amount = 0
local reported_errors = {}


local lib = {}


--- Formats a table to a human readable string
-- @param t table to be formatted
-- @return formatted table (as a string)
local function format_table(t)
  local result = '{ '
  for _, v in ipairs(t) do
    local type_v = type(v)
    if type_v == 'table' then
      result = result .. format_table(v) .. ' '
    elseif type_v == 'boolean' then
      result = result .. (v and 'true ' or 'false ')
    else
      result = result .. v .. ' '
    end
  end
  return result .. '}'
end


--- Writes a string to stdout (no newline at end).
-- @param s string to be written to stdout
function lib.report(s) write(s) end


--- Prints the used random seed to stdout.
-- @param seed Random seed to be printed to stdout
function lib.report_seed(seed)
  lib.report('Random seed = ' .. seed .. '\n')
end


--- Prints a '.' to stdout
function lib.report_success()
  passed_amount = passed_amount + 1
  lib.report '.'
end


--- Prints a green '.' to stdout
local function report_success_colored()
  passed_amount = passed_amount + 1
  lib.report '\27[32m.\27[0m'
end


--- Prints a 'x' to stdout
function lib.report_skipped()
  skipped_amount = skipped_amount + 1
  lib.report 'x'
end


--- Prints a yellow 'x' to stdout
local function report_skipped_colored()
  skipped_amount = skipped_amount + 1
  lib.report '\27[33mx\27[0m'
end


--- Prints an 'F' to stdout
function lib.report_failed()
  failed_amount = failed_amount + 1
  lib.report 'F'
end


--- Prints a red 'F' to stdout
local function report_failed_colored()
  failed_amount = failed_amount + 1
  lib.report '\27[31mF\27[0m'
end


--- Saves an error to the list of errors.
function lib.save_error(failure_str)
  table.insert(reported_errors, failure_str)
end


--- Prints out information regarding the failed property
function lib.report_failed_property(property, generated_values, shrunk_values)
  lib.save_error('\nProperty "' .. property.description .. '" failed!\n'
                .. 'Generated values = ' .. format_table(generated_values) .. '\n'
                .. 'Simplified solution to = ' .. format_table(shrunk_values) .. '\n')
end


--- Prints out information regarding the failed FSM.
function lib.report_failed_fsm(description)
  -- TODO output more information
  lib.save_error('\nFSM ' .. description .. ' failed!\n')
end


--- Reports all errors to stdout.
function lib.report_errors()
  map(reported_errors, lib.report)
  lib.report '\n'  -- extra newline as separator between errors
end


--- Prints a summary about certain statistics (test passed / failed, ...)
function lib.report_summary()
  local total_tests = passed_amount + failed_amount + skipped_amount
  lib.report('' .. total_tests .. ' tests, '
                .. failed_amount .. ' failures, '
                .. skipped_amount .. ' skipped.\n')
end


--- Configures this module to use ANSI colors when printing to terminal or not.
-- @param enable_colors true: colors will be used when printing to terminal;
--                      otherwise plain text will be printed.
function lib.configure(enable_colors)
  if not enable_colors then return end
  lib.report_success = report_success_colored
  lib.report_skipped = report_skipped_colored
  lib.report_failed = report_failed_colored
end


return lib

