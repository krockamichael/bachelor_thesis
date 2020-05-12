# push

Lua library implementing knockout.js-like observable properties.

## Table Of Contents
1. [Basics](#zzz)
    - [Properties](#properties)
    - [Push notifications](#push-notifications)
    - [Readonly](#readonly-a-writeproxy-example)
    - [Computed properties](#computed-properties)
2. [The nifty stuff](#the-nifty-stuff)
    - [Recording data dependencies](#record-pulls)
    - [Writeproxies](#introduce-a-new-writeproxy)
3. [Recap for extensiblity](#recap-for-extensibility)

## So... what exactly?
When dealing with keeping multiple data layers in sync as common in GUIs (View-ViewModel or View-Model relations), it is easy to introduce bugs and unfocused code blocks. 
The actual intent is shadowed by syncing boilerplate for all form fields/model bindings. 

That is especially true for HTML applications, where databinding is additionally complicated by DOM access, and here [knockout.js](http://knockoutjs.com/) kicks in. This library tries to provide the observable part as a modular core for other projects. It is actually written in [MoonScript](http://moonscript.org/) and as such the lua files are a nice autogenerated byproduct (and nothing more to me).

## Zzz...
By now your eyes pretty much fast forwarded to the code samples... Anyway, assume `local push = require "push"` has happened before each snippet. There will always be a MoonScript example first, then lua.

### Properties
*push's* building block.
```
p = push.property "foo", "my property" -- (initial val, descriptive name)
assert p! == "foo" -- get
p "goo" -- set
assert p! == "goo"
assert p("hoo") == "hoo" -- set returns new value
assert p.name == "my property"
```
```
local p = push.property("foo", "my property") -- (initial val, descriptive name)
assert(p() == "foo") -- get
p("goo") -- set
assert(p() == "goo")
assert(p("hoo") == "hoo") -- set returns new value
assert(p.name == "my property")
```

### Push notifications
This is were it gets interesting...
```
p = push.property! -- default initialization to (nil, "<unnamed>")
val = nil
p.push_to (nv) -> val = nv -- handle property changes
p "bar"
assert val == "bar"
```
```
local p = push.property() -- default initialization to (nil, "<unnamed>")
local val = nil
p.push_to(function(nv) val = nv end) -- handle property changes
p("bar")
assert(val == "bar")
```

### Readonly: A writeproxy example
The usual OO info hiding stuff: Restrict clients to get access, while internally being able to set stuff. The implementation demonstrates a possible usage of the writeproxy method.
```
p = push.property "zazoo"
get = push.readonly p -- proxies writes to error
assert get! == "zazoo"
assert not pcall get, "kazoom" -- writing to p is not allowed
p "kazoom"
assert get! == "kazoom" -- still propagates changes from wrapped property
```
```
local p = push.property("zazoo")
local get = push.readonly(p)
assert(get() == "zazoo")
assert(not pcall(get, "kazoom"))
p("kazoom")
return assert(get() == "kazoom")
```

### Computed properties
This is the main reason to use *push*. It makes binding form fields a calk walk, because property changes are literally pushed into each dependant property, thereby using a reasonable caching policy:
```
p = push.property "foo"
buzzer = push.computed -> p! .. "buzz" -- the reader computes new dependent value
assert p! == "foo"
assert buzzer! == "foobuzz"
p "bar"
assert buzzer! == "barbuzz"
```
```
local p = push.property("foo")
local buzzer = push.computed(function() 
  -- the reader computes new dependent value
  return p() .. "buzz"
end)
assert(p() == "foo")
assert(buzzer() == "foobuzz")
p("bar")
return assert(buzzer() == "barbuzz")
```
'Can't I write to it?', I hear you think. Yes you can!
```
first = push.property "john"
last = push.property "doe"
reader = -> first! .. " " .. last!
writer = (nv) ->
  f, l = nv\gmatch("(%w+) (%w+)")!
  first f or ""
  last l or ""
  nv
full = push.computed reader, writer, "my fullname"
assert full.name == "my fullname" -- yeah, can still have that
assert full! == "john doe"
full "ron foe" -- interesting bit
assert first! == "ron"
assert last! == "foe"
```
```
local first = push.property("john")
local last = push.property("doe")
local reader
reader = function()
  return first() .. " " .. last()
end
local writer
writer = function(nv)
  local f, l = nv:gmatch("(%w+) (%w+)")()
  first(f or "")
  last(l or "")
  return nv
end
local full = push.computed(reader, writer, "my fullname")
assert(full.name == "my fullname") -- yeah, can still have that
assert(full() == "john doe")
full("ron foe") -- interesting bit
assert(first() == "ron")
return assert(last() == "foe")
```
Now if you don't want a referenced property to push to your `computed()` value, use `peek()`:
```
a = push.property 1, "changes too often"
b = push.property 2, "changes often enough"
c = push.computed -> a\peek! + b!
assert c! == 3
a 15
assert c! == 3 -- the reader isn't even run
b -3
assert c! == 12 -- but when b changes, the new value of a is used
```
```
local a = push.property(1, "changes too often")
local b = push.property(2, "changes often enough")
local c = push.computed(function()
  return a:peek() + b()
end)
assert(c() == 3)
a(15)
assert(c() == 3) -- the reader isn't even run
b(-3)
return assert(c() == 12) -- but when b changes, the new value of a is used
```
This were all basic features.

## The nifty stuff
If you feel comfortable with using *push* (which should not take that long), you might desire some seams for extensibility. If those *push* provides you are not generic enough, open an issue please.

### Record pulls
If you need to know from which properties a function acquires its data, use `record_pulls(func)`. 
It executes `func()` and monitors any accessed properties.
These are returned as well as the result of the function execution.
In case `func()` errors, it returns the (false, err) tuple.
```
a = push.property true
b = push.property 5
unused = push.property!
func = -> if a! then b! else unused!
pulls, result = push.record_pulls func
assert result == b!
assert pulls[a] == a
assert pulls[b] == b
assert pulls[unused] == nil
```
```
local a = push.property(true)
local b = push.property(5)
local unused = push.property()
local func
func = function()
  if a() then
    return b()
  else
    return unused()
  end
end
local pulls, result = push.record_pulls(func)
assert(result == b())
assert(pulls[a] == a)
assert(pulls[b] == b)
return assert(pulls[unused] == nil)
```

### Introduce a new writeproxy
As I captioned earlier, `readonly(p)` is a simple writeproxy. It is also used in `computed()` to wire up the writer with the actual setter.
You can look at the implementation of those to get a feel, but I will also guide you through implementing a basic range restrictor for numeric values.
`writeproxy(f)` takes a unary function which gets passed the value when the property is set. 
It's your responsibility to process that value and then return what the properties new value should be 
(By the way, that's why most of the text here is code... That paragraph reads horribly). Only using MoonScript from now on.
Say our new decorator should be called like
```
r = filter between(5, 10), push.property 7
assert r(11) == 7
assert r(6) == 6
```
This is actually flawed from a design perspective (what if the prop is modified though another accessor or you want in/exclusive bounds?), but looks appealing.
`between(from, to)` returns a simple predicate:
```
between = (f, t) -> 
  (v) -> v >= f and v <= t
```
and `filter(pred, prop) can be implemented like
```
filter = (pred, prop) ->
  prop\writeproxy (nv) ->
    if pred nv then nv else prop!
```
The last line reads 'If the new value matches the predicate, return (and therefore set) the new value, else the current value.'
You and I could spin that even further to improve the syntax and come up with solutions for the accessor problem... But at least for me that'll have to wait.
This enables you to write even more elaborate things I can't even think of at the moment.

## Recap for extensibility
In short, you just need to be aware of these three seams to extend *push* in a proper way:

1. `push_to()` notifications (notifies even if not written through the setter, but after the value changed)
2. `writeproxy()` for write interceptions through the local setter
3. `record_pulls()` if you want to where a particular piece of code pulls its data from.