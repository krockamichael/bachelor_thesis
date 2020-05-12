# lualink
A linker for lua code

lualink puts all your dependencies inside one file, so that you can embed it easily.

## How does it work ?
It just puts the content of your file as functions inside _package.preload_.

Let's say your lua program has two files: _main.lua_ and its dependency _foo.lua_

```lua
-- main.lua

local foo = require "foo"

print "hello from main.lua"
foo.sayhello()
```

```lua
-- foo.lua

return {
	sayhello= function() print("hello from dep.lua") end
}
```

Just link it :

    $ ./lualink -mmain=main.lua -mfoo=foo.lua -o myapp.lua

Now all your dependencies are inside _myapp.lua_

```sh
$ rm main.lua dep.lua
$ lua myapp.lua
hello from main.lua
hello from dep.lua
```

As you can see, it just puts your files _inline_.
    
```lua
-- myapp.lua

package.preload['main'] = function()
	local m = require "foo"

	print "hello from main.lua"
	foo.sayhello()
end

package.preload['foo'] = function()
	return {
		sayhello= function() print("hello from foo.lua") end
	}
end

require('main')
```

So it's not perfect:

- You can't embed bytecode (but you can easily compile the file produced)
- It alterates debug informations

Pull requests are open !
