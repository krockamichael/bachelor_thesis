local insert, concat
do
  local _obj_0 = table
  insert, concat = _obj_0.insert, _obj_0.concat
end
local unpack = unpack or table.unpack
local lpeg = require("lpeg")
local R, S, V, P
R, S, V, P = lpeg.R, lpeg.S, lpeg.V, lpeg.P
local C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp
C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp = lpeg.C, lpeg.Cs, lpeg.Ct, lpeg.Cmt, lpeg.Cg, lpeg.Cb, lpeg.Cc, lpeg.Cp
local escaped_char = S("<>'&\"") / {
  [">"] = "&gt;",
  ["<"] = "&lt;",
  ["&"] = "&amp;",
  ["'"] = "&#x27;",
  ["/"] = "&#x2F;",
  ['"'] = "&quot;"
}
local alphanum = R("az", "AZ", "09")
local num = R("09")
local hex = R("09", "af", "AF")
local valid_char = C(P("&") * (alphanum ^ 1 + P("#") * (num ^ 1 + S("xX") * hex ^ 1)) + P(";"))
local white = S(" \t\n") ^ 0
local text = C((1 - escaped_char) ^ 1)
local word = (alphanum + S("._-:")) ^ 1
local value = C(word) + P('"') * C((1 - P('"')) ^ 0) * P('"') + P("'") * C((1 - P("'")) ^ 0) * P("'")
local attribute = C(word) * (white * P("=") * white * value) ^ -1
local comment = P("<!--") * (1 - P("-->")) ^ 0 * P("-->")
local value_ignored = word + P('"') * (1 - P('"')) ^ 0 * P('"') + P("'") * (1 - P("'")) ^ 0 * P("'")
local attribute_ignored = word * (white * P("=") * white * value_ignored) ^ -1
local open_tag_ignored = P("<") * white * word * (white * attribute_ignored) ^ 0 * white * (P("/") * white) ^ -1 * P(">")
local close_tag_ignored = P("<") * white * P("/") * white * word * white * P(">")
local escape_text = Cs((escaped_char + 1) ^ 0 * -1)
local Sanitizer
Sanitizer = function(opts)
  local allowed_tags, add_attributes, self_closing
  do
    local _obj_0 = opts and opts.whitelist or require("web_sanitize.whitelist")
    allowed_tags, add_attributes, self_closing = _obj_0.tags, _obj_0.add_attributes, _obj_0.self_closing
  end
  local tag_stack = { }
  local attribute_stack = { }
  local tag_has_dynamic_add_attribute
  tag_has_dynamic_add_attribute = function(tag)
    local inject = add_attributes[tag]
    if not (inject) then
      return false
    end
    for _, v in pairs(inject) do
      if type(v) == "function" then
        return true
      end
    end
    return false
  end
  local check_tag
  check_tag = function(str, pos, tag)
    local lower_tag = tag:lower()
    local allowed = allowed_tags[lower_tag]
    if not (allowed) then
      return false
    end
    insert(tag_stack, lower_tag)
    return true, tag
  end
  local check_close_tag
  check_close_tag = function(str, pos, punct, tag, rest)
    local lower_tag = tag:lower()
    local top = #tag_stack
    pos = top
    while pos >= 1 do
      if tag_stack[pos] == lower_tag then
        break
      end
      pos = pos - 1
    end
    if pos == 0 then
      return false
    end
    local buffer = { }
    local k = 1
    for i = top, pos + 1, -1 do
      local _continue_0 = false
      repeat
        local next_tag = tag_stack[i]
        tag_stack[i] = nil
        if attribute_stack[i] then
          attribute_stack[i] = nil
        end
        if self_closing[next_tag] then
          _continue_0 = true
          break
        end
        buffer[k] = "</"
        buffer[k + 1] = next_tag
        buffer[k + 2] = ">"
        k = k + 3
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
    tag_stack[pos] = nil
    if attribute_stack[pos] then
      attribute_stack[pos] = nil
    end
    buffer[k] = punct
    buffer[k + 1] = tag
    buffer[k + 2] = rest
    return true, unpack(buffer)
  end
  local pop_tag
  pop_tag = function(str, pos, ...)
    local idx = #tag_stack
    tag_stack[idx] = nil
    if attribute_stack[idx] then
      attribute_stack[idx] = nil
    end
    return true, ...
  end
  local fail_tag
  fail_tag = function()
    local idx = #tag_stack
    tag_stack[idx] = nil
    if attribute_stack[idx] then
      attribute_stack[idx] = nil
    end
    return false
  end
  local check_attribute
  check_attribute = function(str, pos_end, pos_start, name, value)
    local tag_idx = #tag_stack
    local tag = tag_stack[tag_idx]
    local lower_name = name:lower()
    local allowed_attributes = allowed_tags[tag]
    if type(allowed_attributes) ~= "table" then
      return true
    end
    if tag_has_dynamic_add_attribute(tag) then
      local attributes = attribute_stack[tag_idx]
      if not (attributes) then
        attributes = { }
        attribute_stack[tag_idx] = attributes
      end
      attributes[lower_name] = value
      table.insert(attributes, {
        name,
        value
      })
    end
    local attr = allowed_attributes[lower_name]
    local new_val
    if type(attr) == "function" then
      new_val = attr(value, name, tag)
      if not (new_val) then
        return true
      end
    else
      if not (attr) then
        return true
      end
    end
    if type(new_val) == "string" then
      return true, " " .. tostring(name) .. "=\"" .. tostring(assert(escape_text:match(new_val))) .. "\""
    else
      return true, str:sub(pos_start, pos_end - 1)
    end
  end
  local inject_attributes
  inject_attributes = function()
    local tag_idx = #tag_stack
    local top_tag = tag_stack[tag_idx]
    local inject = add_attributes[top_tag]
    if inject then
      local buff = { }
      local i = 1
      for k, v in pairs(inject) do
        local _continue_0 = false
        repeat
          if type(v) == "function" then
            v = v(attribute_stack[tag_idx] or { })
          end
          if not (v) then
            _continue_0 = true
            break
          end
          buff[i] = " "
          buff[i + 1] = k
          buff[i + 2] = '="'
          buff[i + 3] = v
          buff[i + 4] = '"'
          i = i + 5
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      return true, unpack(buff)
    else
      return true
    end
  end
  local tag_attributes = Cmt(Cp() * white * attribute, check_attribute) ^ 0
  local open_tag = C(P("<") * white) * Cmt(word, check_tag) * (tag_attributes * C(white) * Cmt("", inject_attributes) * (Cmt("/" * white * ">", pop_tag) + C(">")) + Cmt("", fail_tag))
  local close_tag = Cmt(C(P("<") * white * P("/") * white) * C(word) * C(white * P(">")), check_close_tag)
  if opts and opts.strip_tags then
    open_tag = open_tag + open_tag_ignored
    close_tag = close_tag + close_tag_ignored
  end
  if opts and opts.strip_comments then
    open_tag = comment + open_tag
  end
  local html = Ct((open_tag + close_tag + valid_char + escaped_char + text) ^ 0 * -1)
  return function(str)
    tag_stack = { }
    local buffer = assert(html:match(str), "failed to parse html")
    local k = #buffer + 1
    for i = #tag_stack, 1, -1 do
      local _continue_0 = false
      repeat
        local tag = tag_stack[i]
        if self_closing[tag] then
          _continue_0 = true
          break
        end
        buffer[k] = "</"
        buffer[k + 1] = tag
        buffer[k + 2] = ">"
        k = k + 3
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
    return concat(buffer)
  end
end
local Extractor
Extractor = function(opts)
  local html_text = Ct((open_tag_ignored / " " + close_tag_ignored / " " + valid_char + escaped_char + text) ^ 0 * -1)
  return function(str)
    local buffer = assert(html_text:match(str), "failed to parse html")
    local out = concat(buffer)
    out = out:gsub("%s+", " ")
    return (out:match("^%s*(.-)%s*$"))
  end
end
return {
  Sanitizer = Sanitizer,
  Extractor = Extractor,
  escape_text = escape_text
}
