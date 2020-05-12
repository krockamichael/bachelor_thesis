--- Buffer Class
--
Buffer = {}
Buffer.new = function(...)
	local arg = {...}
	local o = {
		buffer_length = 0,
		buffer = {},
		encoding = "",
		Buffer = true
	}

	---
	--
	o.slice = function(self, from, to)
		local ret = {}
		from = from + 1
		for i, value in ipairs(self.buffer) do
			if i >= from and i <= to then
				table.insert(ret, value)
			end
		end
		return Buffer.new(ret)
	end

	---
	--
	o.length = function(self)
		return self.buffer_length
	end

	---
	--
	o.at = function(self, index)
		return self.buffer[index + 1]
	end

	---
	--
	o.writeAt = function(self, index, value)
		if value > 0xff then
			value = 0xff
		end
		self.buffer[index + 1] = value
		self.buffer_length = #self.buffer
	end

	---
	--
	o.toString = function(self, toEncode)
		if self.buffer_length == 0 then
			return "toString() is null!"
		end

		if toEncode == "UCS2" then
			--return wstringToUtf8(self.buffer);
			error("not support")
		else
			local bytearr = {}
			for _, v in ipairs(self.buffer) do
			local utf8byte = v < 0 and (0xff + v + 1) or v
				table.insert(bytearr, string.char(utf8byte))
			end
			return table.concat(bytearr)
		end
	end

	if arg[1] == nil and arg[2] == nil then
		o.encoding = "unknown"
	elseif arg[1] ~= nil and arg[2] == nil then
		if type(arg[1]) == "table" then
			assert(type(arg[1]) == "table", "must be table")
			o.buffer = arg[1]
			o.buffer_length = #arg[1]
			o.encoding = "unknown"
		elseif type(arg[1]) == "string" then
			assert(type(arg[1]) == "string", "must be string")
			o.buffer_length = 0--arg[1]
			o.encoding = "unknown"
			for i = 1, string.len(arg[1]) do
				o.buffer[i] = arg[1]:byte(i)
			end
			o.buffer_length = string.len(arg[1])
		else
			assert(type(arg[1]) == "number", "must be number")
			o.buffer_length = 0--arg[1]
			o.encoding = "unknown"
		end
	elseif arg[1] ~= nil and arg[2] ~= nil then
		assert(type(arg[1]) == "string", "must be string")
		assert(type(arg[2]) == "string", "must be string")
		if type(arg[1]) == "string" then
			for i = 1, string.len(arg[1]) do
				o.buffer[i] = arg[1]:byte(i)
			end
		end
		o.buffer_length = string.len(arg[1])
		o.encoding = arg[2]
	else
		assert(false)
	end

	return o
end
