# ppkit
ppkit is a Lua library that lets you create preprocessors based in lxpp-syntax.
## Installing
You can use luarocks to automatically install ppkit and its dependencies.
```
# luarocks install ppkit
```
## Usage
### Creating a spec
A spec is a Lua table that will do all replacements, it generally consists of the following structure:
```lua
{
  name    = "pp-name",
  version = "v1",
  defines = { ... }
}
```
`.defines` will contain all of the definitions for the spec.
### Creating a definition
A definition helps you create a grammar rule for your preprocessor/compiler. They can be similar to those in Atom .cson grammars.
A name is often assigned in the same format, with the preprocessor name last and categories. For example `keyword.control.using.night`.
```lua
defines = {
  {
    name      = "paragraph.quickdown"
    condition = "%+{",
    capture   = {
      [1] = "%+{"
    },
    replace   = {
      [1] = "<p>"
    },
    mode      = {
      i_counter = "paragraph.quickdown:indent"
    }
  }
}
```
So here we can see several things:
- `.defines.capture` is a table that contains the captures for the line
- `.defines.replace` contains matching strings that will be replaced in the line
- `.defines.mode` is used to set, remove, increment or decrement modes.
#### `.defines.capture`
Here we set all the captures for a single line. The number can be negative if you want to do a single replace rather than all possible. That would also let you use `^` and `$` in the pattern.
#### `.defines.replace`
The replaces for each pattern should have the same index, even when they are negative. You can use gsub placeholders like `%1`.
#### `.defines.mode`
This enables you to keep track of the state of the compiler.
- Keys prefixed with `a` will add the flag in their value.
- Keys prefixed with `r` will remove the flag in their value.
- Keys prefixed with `i` will increrment a flag's value.
- Keys prefixed with `d` will decrement a flag's value.
- Keys prefixed with `t` will terminate flag processing.
- Keys prefixed with `c` will create a condition on a flag.
Conditions are useful whenever you want to, for example, close tags after opening them.
## License
This library is licensed under the MIT license.
Made by [daelvn](https://github.com/daelvn)

