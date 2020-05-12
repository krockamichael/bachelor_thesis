# ftcsv
[![Build Status](https://travis-ci.org/FourierTransformer/ftcsv.svg?branch=master)](https://travis-ci.org/FourierTransformer/ftcsv) [![Coverage Status](https://coveralls.io/repos/github/FourierTransformer/ftcsv/badge.svg?branch=master)](https://coveralls.io/github/FourierTransformer/ftcsv?branch=master)

ftcsv is a fast pure lua csv library.

It works well for CSVs that can easily be fully loaded into memory (easily up to a hundred MB) and correctly handles `\n` (LF), `\r` (CR) and `\r\n` (CRLF) line endings. It has UTF-8 support, and will strip out the BOM if it exists. ftcsv can also parse headerless csv-like files and supports column remapping, file or string based loading, and more!

Currently, there isn't a "large" file mode with proper readers for ingesting large CSVs using a fixed amount of memory, but that is in the works in [another branch!](https://github.com/FourierTransformer/ftcsv/tree/parseLineIterator)

It's been tested with LuaJIT 2.0/2.1 and Lua 5.1, 5.2, and 5.3



## Installing
You can either grab `ftcsv.lua` from here or install via luarocks:

```
luarocks install ftcsv
```


## Parsing
### `ftcsv.parse(fileName, delimiter [, options])`

ftcsv will load the entire csv file into memory, then parse it in one go, returning a lua table with the parsed data and a lua table containing the column headers. It has only two required parameters - a file name and delimiter (limited to one character). A few optional parameters can be passed in via a table (examples below).

Just loading a csv file:
```lua
local ftcsv = require('ftcsv')
local zipcodes, headers = ftcsv.parse("free-zipcode-database.csv", ",")
```

### Options
The following are optional parameters passed in via the third argument as a table. For example if you wanted to `loadFromString` and not use `headers`, you could use the following:
```lua
ftcsv.parse("apple,banana,carrot", ",", {loadFromString=true, headers=false})
```
 - `loadFromString`

 	If you want to load a csv from a string instead of a file, set `loadFromString` to `true` (default: `false`)
 	```lua
	ftcsv.parse("a,b,c\r\n1,2,3", ",", {loadFromString=true})
 	```

 - `rename`

 	If you want to rename a field, you can set `rename` to change the field names. The below example will change the headers from `a,b,c` to `d,e,f`

 	Note: You can rename two fields to the same value, ftcsv will keep the field that appears latest in the line.

 	```lua
 	local options = {loadFromString=true, rename={["a"] = "d", ["b"] = "e", ["c"] = "f"}}
	local actual = ftcsv.parse("a,b,c\r\napple,banana,carrot", ",", options)
 	```

 - `fieldsToKeep`

 	If you only want to keep certain fields from the CSV, send them in as a table-list and it should parse a little faster and use less memory.

 	Note: If you want to keep a renamed field, put the new name of the field in `fieldsToKeep`:

 	```lua
	local options = {loadFromString=true, fieldsToKeep={"a","f"}, rename={["c"] = "f"}}
	local actual = ftcsv.parse("a,b,c\r\napple,banana,carrot\r\n", ",", options)
 	```

 - `headerFunc`

 	Applies a function to every field in the header. If you are using `rename`, the function is applied after the rename.

 	Ex: making all fields uppercase
 	```lua
 	local options = {loadFromString=true, headerFunc=string.upper}
	local actual = ftcsv.parse("a,b,c\napple,banana,carrot", ",", options)
 	```

 - `headers`

 	Set `headers` to `false` if the file you are reading doesn't have any headers. This will cause ftcsv to create indexed tables rather than a key-value tables for the output.

 	```lua
	local options = {loadFromString=true, headers=false}
	local actual = ftcsv.parse("apple>banana>carrot\ndiamond>emerald>pearl", ">", options)
 	```

 	Note: Header-less files can still use the `rename` option and after a field has been renamed, it can specified as a field to keep. The `rename` syntax changes a little bit:

 	```lua
	local options = {loadFromString=true, headers=false, rename={"a","b","c"}, fieldsToKeep={"a","b"}}
	local actual = ftcsv.parse("apple>banana>carrot\ndiamond>emerald>pearl", ">", options)
 	```

 	In the above example, the first field becomes 'a', the second field becomes 'b' and so on.

For all tested examples, take a look in /spec/feature_spec.lua and /spec/dynamic_features_spec.lua


## Encoding
### `ftcsv.encode(inputTable, delimiter[, options])`

ftcsv can also take a lua table and turn it into a text string to be written to a file. It has two required parameters, an inputTable and a delimiter. You can use it to write out a file like this:
```lua
local fileOutput = ftcsv.encode(users, ",")
local file = assert(io.open("ALLUSERS.csv", "w"))
file:write(fileOutput)
file:close()
```

### Options
 - `fieldsToKeep`

	if `fieldsToKeep` is set in the encode process, only the fields specified will be written out to a file.

	```lua
	local output = ftcsv.encode(everyUser, ",", {fieldsToKeep={"Name", "Phone", "City"}})
	```


## Error Handling
ftcsv returns a bunch of errors when passed a bad csv file or incorrect parameters. You can find a more detailed explanation of the more cryptic errors in [ERRORS.md](ERRORS.md)


## Benchmarks
We ran ftcsv against a few different csv parsers ([PIL](http://www.lua.org/pil/20.4.html)/[csvutils](http://lua-users.org/wiki/CsvUtils), [lua_csv](https://github.com/geoffleyland/lua-csv), and [lpeg_josh](http://lua-users.org/lists/lua-l/2009-08/msg00020.html)) for lua and here is what we found:

### 20 MB file, every field is double quoted (ftcsv optimal lua case\*)

| Parser    | Lua                | LuaJIT             |
| --------- | ------------------ | ------------------ |
| PIL/csvutils  | 3.939 +/- 0.565 SD | 1.429 +/- 0.175 SD |
| lua_csv   | 8.487 +/- 0.156 SD | 3.095 +/- 0.206 SD |
| lpeg_josh | **1.350 +/- 0.191 SD** | 0.826 +/- 0.176 SD |
| ftcsv     | 3.101 +/- 0.152 SD | **0.499 +/- 0.133 SD** |

\* see Performance section below for an explanation

### 12 MB file, some fields are double quoted

| Parser    | Lua                | LuaJIT             |
| --------- | ------------------ | ------------------ |
| PIL/csvutils  | 2.868 +/- 0.101 SD | 1.244 +/- 0.129 SD |
| lua_csv   | 7.773 +/- 0.083 SD | 3.495 +/- 0.172 SD |
| lpeg_josh | **1.146 +/- 0.191 SD** | 0.564 +/- 0.121 SD |
| ftcsv     | 3.401 +/- 0.109 SD | **0.441 +/- 0.124 SD** |

[LuaCSV](http://lua-users.org/lists/lua-l/2009-08/msg00012.html) was also tried, but usually errored out at odd places during parsing.

NOTE: times are measured using `os.clock()`, so they are in CPU seconds. Each test was run 30 times in a randomized order. The file was pre-loaded, and only the csv decoding time was measured.

Benchmarks were run under ftcsv 1.1.6

## Performance
We did some basic testing and found that in lua, if you want to iterate over a string character-by-character and look for single chars, `string.byte` performs faster than `string.sub`. This is especially true for LuaJIT. As such, in LuaJIT, ftcsv iterates over the whole file and does byte compares to find quotes and delimiters. However, for pure lua, `string.find` is used to find quotes but `string.byte` is used everywhere else as the CSV format in its proper form will have quotes around fields. If you have thoughts on how to improve performance (either big picture or specifically within the code), create a GitHub issue - I'd love to hear about it!


## Contributing
Feel free to create a new issue for any bugs you've found or help you need. If you want to contribute back to the project please do the following:

 0. If it's a major change (aka more than a quick bugfix), please create an issue so we can discuss it!
 1. Fork the repo
 2. Create a new branch
 3. Push your changes to the branch
 4. Run the test suite and make sure it still works
 5. Submit a pull request
 6. Wait for review
 7. Enjoy the changes made!



## Licenses
 - The main library is licensed under the MIT License. Feel free to use it!
 - Some of the test CSVs are from [csv-spectrum](https://github.com/maxogden/csv-spectrum) (BSD-2-Clause) which includes some from [csvkit](https://github.com/wireservice/csvkit) (MIT License)
