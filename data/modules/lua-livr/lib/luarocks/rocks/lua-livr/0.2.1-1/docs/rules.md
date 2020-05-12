
# LIVR

---

# Rules

More rules are available with <https://fperrad.frama.io/lua-LIVR-extra>.

## Common Rules

See <http://livr-spec.org/validation-rules/common-rules.html>.

#### required


#### not\_empty


#### not\_empty\_list


#### any\_object


## String Rules

See <http://livr-spec.org/validation-rules/string-rules.html>.

#### string


#### eq


#### one\_of


#### max\_length


#### min\_length


#### length\_between


#### length\_equal

The correct computation of the length of UTF-8 string requires **Lua 5.3**,
or [compat53](https://github.com/keplerproject/lua-compat-5.3)
or [lua-utf8](https://github.com/starwing/luautf8).

#### like

[Lrexlib-PCRE](https://rrthomas.github.io/lrexlib/) allows the use of
[PCRE](https://en.wikipedia.org/wiki/Perl_Compatible_Regular_Expressions) regexp,
otherwise `like` behaves as `like_lua`.

#### like_lua

This rule allows to use [Lua patterns](https://www.lua.org/manual/5.3/manual.html#6.4.1)
as regexp.

## Numeric Rules

See <http://livr-spec.org/validation-rules/numeric-rules.html>.

#### integer


#### positive\_integer


#### decimal


#### positive\_decimal


#### max\_number


#### min\_number


#### number\_between


## Special Rules

See <http://livr-spec.org/validation-rules/special-rules.html>.

#### email


#### url


#### iso\_date


#### equal\_to\_field


## Metarules

See <http://livr-spec.org/validation-rules/metarules.html>.

#### nested\_object


#### variable\_object


#### list\_of


#### list\_of\_objects


#### list\_of\_different\_objects


#### or \(experimental\)


## Modifiers

See <http://livr-spec.org/validation-rules/modifiers.html>.

#### trim


#### to\_lc

The correct processing of UTF-8 string requires [lua-utf8](https://github.com/starwing/luautf8).

#### to\_uc

The correct processing of UTF-8 string requires [lua-utf8](https://github.com/starwing/luautf8).

#### remove


#### leave\_only


#### default

