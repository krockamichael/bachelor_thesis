local url = require("socket.url")
local insert, concat
do
  local _obj_0 = table
  insert, concat = _obj_0.insert, _obj_0.concat
end
math.randomseed(os.time())
local File
do
  local _base_0 = {
    mime = function(self)
      if not (self._mime) then
        pcall(function()
          local mimetypes = require("mimetypes")
          self._mime = mimetypes.guess(self.fname)
        end)
        if not (self._mime) then
          self._mime = "application/octet-stream"
        end
      end
      return self._mime
    end,
    content = function(self)
      do
        local file = assert(io.open(self.fname), "Failed to open file `" .. tostring(self.fname) .. "`")
        if file then
          do
            local _with_0 = file:read("*a")
            file:close()
            return _with_0
          end
        end
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, fname, _mime)
      self.fname, self._mime = fname, _mime
    end,
    __base = _base_0,
    __name = "File"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  File = _class_0
end
local rand_string
rand_string = function(len)
  local shuffled
  do
    local _accum_0 = { }
    local _len_0 = 1
    for i = 1, len do
      local r = math.random(97, 122)
      if math.random() >= 0.5 then
        r = r - 32
      end
      local _value_0 = r
      _accum_0[_len_0] = _value_0
      _len_0 = _len_0 + 1
    end
    shuffled = _accum_0
  end
  return string.char(unpack(shuffled))
end
local encode
encode = function(params)
  local tuples
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #params do
      local t = params[_index_0]
      _accum_0[_len_0] = t
      _len_0 = _len_0 + 1
    end
    tuples = _accum_0
  end
  for k, v in pairs(params) do
    if type(k) == "string" then
      insert(tuples, {
        k,
        v
      })
    end
  end
  local chunks
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #tuples do
      local tuple = tuples[_index_0]
      local k, v = unpack(tuple)
      k = url.escape(k)
      local buffer = {
        'Content-Disposition: form-data; name="' .. k .. '"'
      }
      local content
      if type(v) == "table" and v.__class == File then
        buffer[1] = buffer[1] .. ('; filename="' .. v.fname .. '"')
        insert(buffer, "Content-type: " .. tostring(v:mime()))
        content = v:content()
      else
        content = v
      end
      insert(buffer, "")
      insert(buffer, content)
      local _value_0 = concat(buffer, "\r\n")
      _accum_0[_len_0] = _value_0
      _len_0 = _len_0 + 1
    end
    chunks = _accum_0
  end
  local boundary
  while true do
    boundary = "Boundary" .. tostring(rand_string(16))
    for _index_0 = 1, #chunks do
      local _continue_0 = false
      repeat
        local c = chunks[_index_0]
        if c:find(boundary) then
          _continue_0 = true
          break
        end
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
    do
      break
    end
  end
  local inner = concat({
    "\r\n",
    "--",
    boundary,
    "\r\n"
  })
  return (concat({
    "--",
    boundary,
    "\r\n",
    concat(chunks, inner),
    "\r\n",
    "--",
    boundary,
    "--",
    "\r\n"
  })), boundary
end
if "test" == ... then
  local http = require("socket.http")
  local ltn12 = require("ltn12")
  local out = { }
  local body, boundary = encode({
    wang = "bang",
    dad = "mad",
    f = File("Makefile")
  })
  http.request({
    url = "http://localhost/dump.php",
    method = "POST",
    sink = ltn12.sink.table(out),
    source = ltn12.source.string(body),
    headers = {
      ["Content-length"] = #body,
      ["Content-type"] = "multipart/form-data; boundary=" .. tostring(boundary)
    }
  })
  print(concat(out))
end
return {
  encode = encode,
  File = File
}
