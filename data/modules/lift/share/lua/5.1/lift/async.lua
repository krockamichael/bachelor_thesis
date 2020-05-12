------------------------------------------------------------------------------
-- Asynchronous programming based on coroutines and futures
------------------------------------------------------------------------------

local assert, next, setmetatable = assert, next, setmetatable
local co_create = coroutine.create
local co_resume = coroutine.resume
local co_running = coroutine.running
local co_yield = coroutine.yield
local dbg_getinfo = debug.getinfo

local to_slash = require'lift.path'.to_slash
local diagnostics = require 'lift.diagnostics'
local pcall = diagnostics.pcall

local uv = require 'luv'
local uv_run, uv_now, uv_close = uv.run, uv.now, uv.close
local uv_new_timer, uv_timer_start = uv.new_timer, uv.timer_start

------------------------------------------------------------------------------
-- Coroutine (thread) Pool
------------------------------------------------------------------------------

local coroutines = {} -- list of free coroutines + map{co = future}
local on_begin  -- called to execute a future
local on_end    -- called with the results of pcall(on_begin(future))

-- Reusable coroutine function. Calls on_begin/on_end in cycles.
local function thread_f(future)
  while true do
    local ok, res = pcall(on_begin, future)
    on_end(future, ok, res)
    future = co_yield(res)
  end
end

-- Allocates a coroutine to a future. Returns a Lua thread.
local function co_alloc(future)
  local n, co = #coroutines
  if n > 0 then
    co = coroutines[n]
    coroutines[n] = nil
  else
    co = co_create(thread_f)
  end
  coroutines[co] = future
  return co
end

-- Deallocates a coroutine currently allocated to a future.
local function co_free(co)
  coroutines[#coroutines+1] = co
  coroutines[co] = nil
end

-- Returns the currently running future and coroutine.
-- Must be called from within a coroutine created by this module.
local function co_get()
  local co = co_running()
  local future = coroutines[co]
  if not future then error('not in a lift.async coroutine', 2) end
  return future, co
end

------------------------------------------------------------------------------
-- Scheduler
------------------------------------------------------------------------------

local resumable = {}  -- map{future = arg} of threads ready to run

-- Schedules a coroutine to be resumed with `arg` as soon as possible.
local function resume_soon(future, arg)
  resumable[future] = arg or false
end

-- Runs all threads until they're either blocked or done.
local function step()
  while true do
    local future, arg = next(resumable)
    if not future then return end
    local co = future.co
    if not co then -- start a new thread
      co = co_alloc(future)
      future.co = co
    end
    local ok, err = co_resume(co, arg)
    if not ok then error('error in future:on_ready callback: '..tostring(err)) end
    resumable[future] = nil
  end
end

------------------------------------------------------------------------------
-- Future (proxy object for an async function call executed in a coroutine)
------------------------------------------------------------------------------

local Future = {} -- Future class
local unchecked_errors = {} -- map of raised, still unchecked errors

function Future:__index(k)
  if k == 'error' then -- getting a failed future's unchecked error
    local err = assert(unchecked_errors[self])
    unchecked_errors[self] = nil
    self.error = err
    return err
  elseif k == 'results' then  -- getting a failed future's results
    error(self.error)            -- raises its error
  end
  return Future[k]
end

function Future:__tostring()
  local info, arg = dbg_getinfo(self.f, 'S'), self.arg
  local file = to_slash(info.short_src) -- normalize paths
  return 'async(function<'..file..':'..info.linedefined..'>'..
    (arg and ', ' or '')..(arg and tostring(arg) or '')..')'
end

-- Registers a function to be called when the future's thread finishes.
-- Signature: function(future, error or nil, results table or nil)
function Future:on_ready(callback)
  local status = self.status
  if status then -- call callback immediately
    if status == 'failed' then
      callback(self, unchecked_errors[self] or self.error)
    else -- fulfilled
      callback(self, nil, self.results)
    end
  else
    self[#self+1] = callback
  end
end

-- Checks whether the future has an error, and if so raises the error.
function Future:check_error()
  local err = self.error
  if err then error(err) end
end

-- Returns whether the future's thread is currently running.
function Future:is_running()
  return self.status == false
end

-- Called by coroutines to execute a new future.
on_begin = diagnostics.trace('[thread] ${future} started',
  function(future)
    future.status = false -- the future's thread is running
    return {future.f(future.arg)}
  end)

-- Called by coroutines when a future completes execution.
on_end = diagnostics.trace('[thread] ${future} ended with ${ok} ${res}',
  function(future, ok, res)
    local error_checked = true
    local cb_err, cb_res -- callback arguments
    if ok then -- future was fulfilled
      cb_res = res
      future.results = res
      future.status = 'fulfilled'
    else -- future raised an error
      cb_err = res
      error_checked = false
      future.error = res
      future.results = nil
      future.status = 'failed'
    end
    -- call callbacks
    for i = 1, #future do
      local checked = future[i](future, cb_err, cb_res)
      error_checked = error_checked or checked
    end
    if not error_checked then
      future.error = nil
      unchecked_errors[future] = res
    end
    -- only reuse coroutine if no errors are raised by callbacks
    co_free(future.co)
  end)

------------------------------------------------------------------------------
-- Plain f(arg) calls from the main thread (event loop)
------------------------------------------------------------------------------

local call_list = {} -- 'front' list: {f1, arg1, f2, arg2, ...}

-- Invokes f(arg) in the next iteration of the event loop.
-- Does NOT create a thread or future. Any error will abort the event loop.
local function call(f, arg)
  local t = call_list
  local n = #t
  t[n+1] = f
  t[n+2] = arg or false
end

local function do_calls()
  local t = call_list
  local n = #t ; if n == 0 then return end
  call_list = {}
  for i = 1, n, 2 do
    t[i](t[i+1])
  end
end

------------------------------------------------------------------------------
-- Module Functions
------------------------------------------------------------------------------

-- Forces run() to exit while there are still threads waiting for events.
-- May cause leaks and bugs. Only call if you want to terminate the application.
local abort = diagnostics.trace(
  '[thread] event loop ABORTED',
  function()
    uv.walk(function(h) if not h:is_closing() then h:close() end end)
  end)

-- Schedules a function to be called asynchronously as `f(arg)` in a coroutine.
-- Returns a future object for interfacing with the async call.
local function async(f, arg)
  local future = setmetatable({f = f, arg = arg, co = false,
    error = false, results = false, status = nil}, Future)
  resumable[future] = future
  return future
end

-- Raises all unchecked errors raised by finished threads.
local function check_errors()
  local future, err = next(unchecked_errors)
  if not future then return end -- no errors
  local list = {}
  repeat
    unchecked_errors[future] = nil
    list[#list+1] = err
    if not err.future then err.future = future end
    future, err = next(unchecked_errors)
  until not future
  diagnostics.aggregate("fatal: ${n} unchecked async error${s}", list):report()
end

-- Runs all async functions to completion. Call this from the main thread.
local run = diagnostics.trace(
  '[thread] event loop started',
  '[thread] event loop finished',
  function()
    local stop
    while 1 do
      do_calls()
      step()
      if stop then
        if not uv_run('nowait') then -- really nothing left?
          return
        else
          stop = false -- oops, we aren't finished
        end
      else
        stop = not uv_run('once')
      end
    end
  end)

-- Suspends the calling thread until `future` becomes ready, or until `timeout`
-- milliseconds have passed. The timeout is optional, and if specified must be
-- a positive integer. If the future is fulfilled, returns true and the
-- future's results table. On timeout, returns false and "timed out".
-- If the future raises an error, returns false and the error.
-- See wait().
local function try_wait(future, timeout)
  local status = future.status
  if status then -- future is ready
    if status == 'failed' then return false, future.error end
    return true, future.results
  end
  local running = co_get()
  if future == running then error('future cannot wait for itself', 2) end
  local res, err, cb
  if timeout then
    local timer = uv_new_timer()
    cb = function(_future, _err, _res)
        if timer == nil then return false end -- ignore second call
        if _future then res, err = _res, _err
        else res, err = false, 'timed out' end
        resume_soon(running)
        uv_close(timer)
        timer = nil
        return true
      end
    uv_timer_start(timer, timeout, 0, cb)
  else
    cb = function(_, _err, _res)
        err, res = _err, _res
        resume_soon(running)
        return true
      end
  end
  future:on_ready(cb)
  co_yield()
  if err then
    if err ~= 'timed out' and not err.future then err.future = future end
    return false, err
  end
  return true, res
end

-- Suspends the calling thread until any future from the list becomes ready.
-- Either returns the first fulfilled future, or nil and the first error.
-- See wait_any().
local function try_wait_any(futures)
  -- first we check if any future is currently ready
  local n, running = #futures, co_get()
  for i = 1, n do
    local f = futures[i]
    if f == running then error('future cannot wait for itself', 2) end
    local status = f.status
    if status then -- future is ready
      if status == 'failed' then return nil, f.error end
      return f
    end
  end
  local first, first_err
  local function callback(future, err, res)
    if first then return false end
    first = future
    first_err = err
    resume_soon(running)
    return true
  end
  for i = 1, n do
    futures[i]:on_ready(callback)
  end
  co_yield()
  if first_err then
    if not first_err.future then first_err.future = first end
    return nil, first_err
  end
  return first
end

-- Suspends the calling thread until all futures in the list become ready.
-- Returns true when all futures are fulfilled, or false and a diagnostic
-- object when errors occur. The diagnostic aggregates all raised errors.
-- See wait_all().
local function try_wait_all(futures)
  local n, errors, running = #futures, nil, co_get()
  local function callback(future, err, res)
    if err then
      if not errors then errors = {err} else errors [#errors+1] = err end
      if not err.future then
        err.future = future -- keep track of which future raised the error
      end
    end
    n = n - 1
    if n == 0 then resume_soon(running) end
    return true
  end
  for i = 1, n do
    local f = futures[i]
    if f == running then error('future cannot wait for itself', 2) end
    f:on_ready(callback)
  end
  if n > 0 then co_yield() end
  if not errors then return true end
  return false, diagnostics.aggregate(
    'fatal: caught ${n} error${s} while waiting for futures', errors):traceback(2)
end

-- Like try_wait() but raises an error on failure. Always returns nil.
local function wait(future, timeout)
  local ok, err = try_wait(future, timeout)
  if not ok then error(err) end
end

-- Like try_wait_any() but raises an error on failure. Always returns nil.
local function wait_any(futures)
  local ok, err = try_wait(futures)
  if not ok then error(err) end
end

-- Like try_wait_all() but raises an error on failure. Always returns nil.
local function wait_all(futures)
  local ok, err = try_wait_all(futures)
  if not ok then
    local nested = err.nested
    if #nested == 1 then err = nested[1] end
    error(err)
  end
end

-- Suspends the calling thread until `dt` milliseconds have passed.
-- Returns the elapsed time spent sleeping, in milliseconds.
local function sleep(dt)
  local timer, running = uv_new_timer(), co_get()
  uv_timer_start(timer, dt, 0, function()
    uv_close(timer)
    resume_soon(running)
  end)
  local t0 = uv_now()
  co_yield()
  return uv_now() - t0
end

------------------------------------------------------------------------------
-- Module Table/Functor
------------------------------------------------------------------------------

return setmetatable({
  -- Private API for modules implementing low-level async code
  _get = co_get,
  _resume = resume_soon,
  -- Public API
  abort = abort,
  async = async,
  call = call,
  check_errors = check_errors,
  now = uv_now,
  run = run,
  running = co_get,
  sleep = sleep,
  try_wait = try_wait,
  try_wait_all = try_wait_all,
  try_wait_any = try_wait_any,
  wait = wait,
  wait_all = wait_all,
  wait_any = wait_any,
}, {__call = function(M, f, arg) -- calling the module == calling async()
  return async(f, arg)
end})
