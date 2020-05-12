
--- Helper module for specifying finite state machines (FSMs) with. Provides a DSL.
-- @module lqc.fsm
-- @alias fsm

local algorithm = require 'lqc.fsm.algorithm'
local state = require 'lqc.fsm.state'
local lqc = require 'lqc.quickcheck'


--- Adds a stop state to the list of states.
-- This is a special predefined state that will stop the FSM from generating
-- more state transitions.
-- @param state_list List of states in the FSM (not including stop state)
-- @return the updated state list (variable modified in place).
local function add_stop_state(state_list)
  table.insert(state_list, state 'stop' {
    precondition = function() return true end,  -- always succeeds
    next_state = function() return nil end,     -- not used
    postcondition = function() return true end  -- always succeeds
  })
  return state_list
end


--- Checks if an object is callable (function or functable):
-- @param obj Object to be checked if it is callable
-- @return true if it is callable; otherwise false
local function is_callable(obj)
  local type_obj = type(obj)
  return type_obj == 'function' or type_obj == 'table'
end


--- Checks if the FSM table contains a valid specification of a state machine
-- @param fsm_table Table containing FSM information/description
-- @return nil; raises an error message if specification is not valid
local function check_valid_fsm_spec(fsm_table)
  if not is_callable(fsm_table.commands) then
    error 'Need to provide list of commands to FSM!'
  end
  if not is_callable(fsm_table.initial_state) then
    error 'Need to provide initial state function to FSM!'
  end

  local states = fsm_table.states
  if type(states) ~= 'table' then
    error 'Need to provide a table of possible states of the FSM!'
  end

  -- States are already checked in state.lua
end


local function default_cleanup() end
local function default_when_fail() end


--- Constructs a new FSM
-- @param description text description of the FSM
-- @param fsm_table table containing FSM info
-- @return FSM object
local function new(description, fsm_table)
  local FSM = {}

  function FSM.check(_)
    return algorithm.check(description, fsm_table)
  end

  return FSM
end


--- Creates a new FSM and inserts it into the list of properties.
-- @param descr Text description of the FSM
-- @param fsm_info_table Table containing information of the FSM
local function fsm(descr, fsm_info_table)
  local function fsm_func(fsm_table)
    fsm_table.states = add_stop_state(fsm_table.states)
    fsm_table.cleanup = fsm_table.cleanup or default_cleanup
    fsm_table.when_fail = fsm_table.when_fail or default_when_fail
    fsm_table.numtests = fsm_table.numtests or lqc.numtests
    fsm_table.numshrinks = fsm_table.numshrinks or lqc.numshrinks

    check_valid_fsm_spec(fsm_table)
    local new_fsm = new(descr, fsm_table)
    table.insert(lqc.properties, new_fsm)
  end

  if fsm_info_table then
    -- Called normally (most likely from Moonscript)
    fsm_func(fsm_info_table)
    return function() end
  end

  -- Called with DSL syntax
  return fsm_func
end


return fsm

