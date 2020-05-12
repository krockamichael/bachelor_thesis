Name
=====
lua-dancing-links - Lua implementation of Donald Knuth's Algorithm 7.2.2.1C for exact cover with colors.

By implementing these algorithms in the Lua programming language,
you can use it in NGINX with lua-nginx-module or in LuaTeX.

To enjoy the following puzzles, you need lua(>= 5.2.0) or luajit(>= 2.1.0) and
place *dlx.lua* in your `LUA_PATH`.

Examples
========

Pentominoes
-----------
- 12 pieces: O P Q R S T U V W X Y Z
```bash
$ lua pentominoes.lua 3 20
Solution: 1
V V V S S S R T W Y Y Y Y Z P P P X U U
V Q S S R R R T W W Y Z Z Z P P X X X U
V Q Q Q Q R T T T W W Z O O O O O X U U

...

Solution: 8
V V V Z W W T T T R Q Q Q Q P P P X U U
V Z Z Z Y W W T R R R S S Q P P X X X U
V Z Y Y Y Y W T R S S S O O O O O X U U

$ lua pentominoes.lua 8 8
Solution: 1
V V V X P P P O
V R X X X P P O
V R R X T T T O
R R Y     T S O
Q Q Y     T S O
Q Y Y Z Z W S S
Q U Y U Z W W S
Q U U U Z Z W W

...

Solution: 520
V V V Z Z U U U
V P P P Z U Y U
V X P P Z Z Y O
X X X     Y Y O
W X R     S Y O
W W R R R S T O
Q W W R S S T O
Q Q Q Q S T T T
```

Sudoku
------

```lua
local sudoku = require "sudoku"

local puzzle = [[
......3..
1..4.....
......1.5
9........
.....26..
....53...
.5.8.....
...9...7.
.83....4.
]]

for board in sudoku(puzzle) do
   for i=1,9 do
      for j=1,9 do
         io.write(board[i][j].." ")
         if j%3==0 then io.write(" ") end
      end
      io.write("\n")
      if i%3==0 then io.write("\n") end
   end
end

--[[
5 9 7  2 1 8  3 6 4
1 3 2  4 6 5  8 9 7
8 6 4  3 7 9  1 2 5

9 1 5  6 8 4  7 3 2
3 4 8  7 9 2  6 5 1
2 7 6  1 5 3  4 8 9

6 5 9  8 4 7  2 1 3
4 2 1  9 3 6  5 7 8
7 8 3  5 2 1  9 4 6
--]]
```

```bash
$ cat s16.dlx | lua solver.lua
Solution 1:
9 3 4  5 1 8  2 6 7
7 6 2  4 9 3  1 8 5
8 5 1  7 6 2  4 9 3

2 8 5  9 7 1  6 3 4
6 4 9  2 3 5  7 1 8
1 7 3  8 4 6  5 2 9

4 1 8  6 5 9  3 7 2
3 2 7  1 8 4  9 5 6
5 9 6  3 2 7  8 4 1

Solution 2:
9 3 4  5 1 8  2 6 7
7 6 2  4 9 3  1 8 5
8 5 1  7 6 2  4 9 3

2 8 5  9 7 1  6 3 4
6 4 9  2 3 5  7 1 8
1 7 3  8 4 6  5 2 9

4 1 8  6 5 9  3 7 2
3 2 7  1 8 4  9 5 6
5 9 6  3 2 7  8 4 1
```

Eight queens puzzle
-------------------

```bash
$ lua queens.lua 8
1:
. . . Q . . . .
. . . . . . Q .
. . . . Q . . .
. . Q . . . . .
Q . . . . . . .
. . . . . Q . .
. . . . . . . Q
. Q . . . . . .

...

92:
Q . . . . . . .
. . . . . . Q .
. . . Q . . . .
. . . . . Q . .
. . . . . . . Q
. Q . . . . . .
. . . . Q . . .
. . Q . . . . .
```

Zebra puzzle
------------

Five people, from five different countries, have five different occupations,
own five different pets, drink five different beverages, and live in a row of
five different colored houses.

- The Englishman lives in a red house.
- The painter comes from Japan.
- The yellow house hosts a diplomat.
- The coffee-lover's house is green.
- The Norwegian's house is hte leftmost.
- The dog's owner is from Spain.
- The milk drinker lives in the middle house.
- The violinist drinks orange juice.
- The white house is just left of the green one.
- The Ukrainian drinks tea.
- The Norwegian lives next to the blue house.
- The sculptor breeds snails.
- The horse lives next to the diplomat.
- The nurse lives next to the fox.

Who trains the zebra, and who prefers to drink just plain water?

```bash
$ lua zebra.lua
diplomat    nurse       sculptor    violinist   painter
Norway      Ukraine     England     Spain       Japan
water       tea         milk        orange      coffee
yellow      blue        red         white       green
fox         horse       snail       dog         zebra
```

Todo
====
- Implement **Algorithm M**

Author
======
Soojin Nam jsunam@gmail.com

License
=======
Public Domain
