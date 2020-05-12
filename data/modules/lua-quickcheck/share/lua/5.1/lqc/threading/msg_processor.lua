
--- Helper module for a message processor that can process incoming messages
--  from other threads.
-- @classmod lqc.threading.msg_processor
-- @alias MsgProcessor


--- Checks if 'x' is callable.
-- @param x value to be checked
-- @return true if callable; otherwise false.
local function is_callable(x)
  local type_x = type(x)
  return type_x == 'function' or type_x == 'table'
end


local MsgProcessor = {
  TASK_TAG = 'task',
  RESULT_TAG = 'result',
  STOP_VALUE = 'stop',
  VOID_RESULT = '__VOID'
}


--- Creates an object that can handle incoming messages.
-- @param msg_box An object that can be used to send and receive incoming messages with
-- @return a new MsgProcessor object
function MsgProcessor.new(msg_box)
  local function main_loop_msg_processor()
    -- TODO init random seed per thread?
    while true do
      local _, cmd = msg_box:receive(nil, MsgProcessor.TASK_TAG)
      if cmd == MsgProcessor.STOP_VALUE then
        return
      elseif is_callable(cmd) then
        -- NOTE: threadpool hangs if it returns nil..
        local result = cmd() or MsgProcessor.VOID_RESULT
        msg_box:send(nil, MsgProcessor.RESULT_TAG, result)
      else
        return
      end
    end
  end

  return main_loop_msg_processor
end


return MsgProcessor

