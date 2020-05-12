local url_value
url_value = function(value)
  return value and (value:match("^https?://") or value:match("^//")) and true
end
local mailto_value
mailto_value = function(value)
  return value and value:match("^mailto:") and true
end
local tags = {
  {
    title = true,
    dir = true,
    lang = true
  },
  a = {
    href = function(...)
      return url_value(...) or mailto_value(...)
    end,
    name = true
  },
  abbr = {
    title = true
  },
  b = true,
  blockquote = {
    cite = true
  },
  br = true,
  cite = true,
  code = true,
  dd = true,
  dfn = {
    title = true
  },
  div = true,
  dl = true,
  dt = true,
  em = true,
  h1 = true,
  h2 = true,
  h3 = true,
  h4 = true,
  h5 = true,
  h6 = true,
  hr = true,
  i = true,
  img = {
    align = true,
    alt = true,
    height = true,
    src = url_value,
    width = true
  },
  kbd = true,
  li = true,
  mark = true,
  ol = true,
  p = true,
  pre = true,
  q = {
    cite = true
  },
  s = true,
  samp = true,
  small = true,
  span = true,
  strike = true,
  strong = true,
  sub = true,
  sup = true,
  table = {
    summary = true,
    width = true
  },
  thead = true,
  tbody = true,
  tfoot = true,
  tr = true,
  td = {
    colspan = true,
    rowspan = true,
    width = true
  },
  th = {
    colspan = true,
    rowspan = true,
    width = true
  },
  time = {
    datetime = true,
    pubdate = true
  },
  u = true,
  ul = true,
  var = true
}
local set_default
set_default = function(tags)
  local default = tags[1]
  if not (default) then
    return 
  end
  local mt = {
    __index = default
  }
  for k, v in pairs(tags) do
    local _continue_0 = false
    repeat
      if not (type(k) == "string") then
        _continue_0 = true
        break
      end
      if type(v) == "table" then
        setmetatable(v, mt)
      else
        tags[k] = setmetatable({ }, mt)
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
end
set_default(tags)
local add_attributes = {
  a = {
    rel = "nofollow"
  }
}
local self_closing = {
  br = true,
  img = true,
  hr = true
}
local clone
clone = function(t)
  if not (type(t) == "table") then
    return t
  end
  local _tbl_0 = { }
  for k, v in pairs(t) do
    _tbl_0[k] = clone(v)
  end
  return _tbl_0
end
return {
  tags = tags,
  add_attributes = add_attributes,
  self_closing = self_closing,
  clone = function(self)
    do
      local _with_0 = clone(self)
      set_default(_with_0.tags)
      return _with_0
    end
  end
}
