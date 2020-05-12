local setmetatable, getmetatable = setmetatable, getmetatable
local type = type

local _M = {}

---
-- helper functions
--
local helpers = require "nozzle.helpers"

local is_callable = helpers.is_callable

-- F .. F -> A
-- F .. f -> A
-- F .. A -> A'
-- A .. F -> A'
-- A1 .. A2 -> A'

---
-- Pipeline metatable
local Pipeline = setmetatable({}, {__index = helpers.Pipeline_mt})
Pipeline.__index = Pipeline
Pipeline.__tostring = helpers.Pipeline_mt.__tostring

function Pipeline.new ()
	return setmetatable({}, Pipeline)
end


---
-- Filter's metatable
local Filter_mt = {}

local function is_filter (v)
	return type(v) == "table" and getmetatable(v) == Filter_mt
end

local function is_pipeline (v)
	return type(v) == "table" and getmetatable(v) == Pipeline
end

Pipeline.__concat = function(a, b)
	if is_pipeline(b) then
		return a:union(b)
	end
	return a:append(b)
end

---
-- Helper method that operates on the filter at the given index of the pipeline and then processes the rest, recursively.
-- Each step calls the filter's input function, then processes the rest of the pipeline and finally calls the filter's
-- output function with the output produced by the pipeline.
--
-- If a filter's input function produces any output, that will be returned instead. The output function won't be called
-- and neither the rest of the pipeline.
--
-- @param pipeline the pipeline that is being processed
-- @param index the index of the pipeline to process
-- @param env the environment table. From this table the filter gets or modifies the input data.
-- @... any extra args, which are passed to the next filter in the pipeline
--
local function Pipeline_call_helper (pipeline, index, env, ...)
	local filter = pipeline[index]

	if is_filter(filter) then
		local output = filter:input(env, ...)
		if output then
			return output
		end
		return filter:output(env, Pipeline_call_helper(pipeline, index + 1, env, ...))

	elseif is_callable(filter) then
		return filter(env, ...)
	else
		error( ("Invalid value %s at index %d of the pipeline"):format(tostring(filter), index) )
	end
end

---
-- Call metamethod for pipelines. Allows us to treat pipelines as function calls.
-- Uses a helper function to call each filter in the chain, using recursion.
--
Pipeline.__call = function(self, ...)
	return Pipeline_call_helper(self, 1, ...)
end

---
-- Concat metamethod. Allows us to chain filters together using the syntax:
--
--  pipeline = filter1 .. filter2 .. lastFilter
--
Filter_mt.__concat = function (a, b)
	assert(b)

	if not is_filter(a) then
		error( ("Attempt to chain something that is not a filter. A %s (%s)"):format(type(a), tostring(a)) )
	end
	
	if is_pipeline(b) then
		return b:prepend(a)

	elseif is_filter(b) or is_callable(b) then
		local pipeline = Pipeline.new()
		return pipeline:append(a):append(b)
	end

	error( ("Unable to chain a %s (%s) to a filter"):format(type(b), tostring(b)) )
end

---
-- tostring metamethod, allows printing the filter name if available
--
Filter_mt.__tostring = helpers.tostring_filter


---
-- sets up the call syntax:
--
-- filter(options)
--
-- where options is a table with the following fields:
-- - name a name given to this filter (optional)
-- - input the input processing function (optional)
-- - output the output processing function (optional)
--
_M.filter = setmetatable(_M, {
	__call = function(_, options)

		-- create the filter
		local filter

		if is_callable(options) then
			filter = setmetatable({ input = options }, Filter_mt)
		else
			options = options or {}
			filter = setmetatable({ name = options.name, input = options.input, output = options.output }, Filter_mt)
		end

		-- the default input function just does nothing
		filter.input = filter.input or function() end

		-- the default output function just ignores its first two arguments
		filter.output = filter.output or helpers.compose( helpers.tail, helpers.tail )
		return filter
	end
})


return _M
