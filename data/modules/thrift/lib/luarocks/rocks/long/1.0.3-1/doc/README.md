Lua Long
========

A Long class for representing a 64 bit two's-complement integer value derived from [long.js](https://github.com/dcodeIO/long.js), which was derived from the [Closure Library](https://github.com/google/closure-library)
for stand-alone use and extended with unsigned support.

[![Build Status](https://travis-ci.org/BixData/lua-long.svg)](https://travis-ci.org/BixData/lua-long)

Background
----------
As of [ECMA-262 5th Edition](http://ecma262-5.com/ELS5_HTML.htm#Section_8.5), "all the positive and negative integers
whose magnitude is no greater than 2<sup>53</sup> are representable in the Number type", which is "representing the
doubleprecision 64-bit format IEEE 754 values as specified in the IEEE Standard for Binary Floating-Point Arithmetic".
The [maximum safe integer](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MAX_SAFE_INTEGER)
in JavaScript is 2<sup>53</sup>-1.

Example: 2<sup>64</sup>-1 is 18446744073709551615 but in JavaScript it evaluates to `18446744073709552000`.

Furthermore, bitwise operators in JavaScript "deal only with integers in the range −2<sup>31</sup> through
2<sup>31</sup>−1, inclusive, or in the range 0 through 2<sup>32</sup>−1, inclusive. These operators accept any value of
the Number type but first convert each such value to one of 2<sup>32</sup> integer values."

In some use cases, however, it is required to be able to reliably work with and perform bitwise operations on the full
64 bits. This is where long.js comes into play.

Installation
------------

```sh
$ luarocks install long
```

Usage
-----

```lua
local Long = require('long')

local longVal = Long:new(0xFFFFFFFF, 0x7FFFFFFF)
print(longVal:toString())
...
```

API
---

#### Long:new(low, high=, unsigned=)

Constructs a 64 bit two's-complement integer, given its low and high 32 bit values as *signed* integers.
See the from* functions below for more convenient ways of constructing Longs.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| low             | *number*        | The low (signed) 32 bits of the long
| high            | *number*        | The high (signed) 32 bits of the long
| unsigned        | *boolean*       | Whether unsigned or not, defaults to `false` for signed

---

#### Long.MAX\_UNSIGNED\_VALUE

Maximum unsigned value.

|                 |                 |
|-----------------|-----------------|
| **@type**       | *!Long*         |

#### Long.MAX_VALUE

Maximum signed value.

|                 |                 |
|-----------------|-----------------|
| **@type**       | *!Long*         |

#### Long.MIN_VALUE

Minimum signed value.

|                 |                 |
|-----------------|-----------------|
| **@type**       | *!Long*         |

#### Long.NEG_ONE

Signed negative one.

|                 |                 |
|-----------------|-----------------|
| **@type**       | *!Long*         |

#### Long.ONE

Signed one.

|                 |                 |
|-----------------|-----------------|
| **@type**       | *!Long*         |

#### Long.UONE

Unsigned one.

|                 |                 |
|-----------------|-----------------|
| **@type**       | *!Long*         |

#### Long.UZERO

Unsigned zero.

|                 |                 |
|-----------------|-----------------|
| **@type**       | *!Long*         |

#### Long.ZERO

Signed zero.

|                 |                 |
|-----------------|-----------------|
| **@type**       | *!Long*         |

#### Long.fromBits(lowBits, highBits, unsigned=)

Returns a Long representing the 64 bit integer that comes by concatenating the given low and high bits. Each is
assumed to use 32 bits.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| lowBits         | *number*        | The low 32 bits
| highBits        | *number*        | The high 32 bits
| unsigned        | *boolean*       | Whether unsigned or not, defaults to `false` for signed
| **@returns**    | *!Long*         | The corresponding Long value

#### Long.fromInt(value, unsigned=)

Returns a Long representing the given 32 bit integer value.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| value           | *number*        | The 32 bit integer in question
| unsigned        | *boolean*       | Whether unsigned or not, defaults to `false` for signed
| **@returns**    | *!Long*         | The corresponding Long value

#### Long.fromNumber(value, unsigned=)

Returns a Long representing the given value, provided that it is a finite number. Otherwise, zero is returned.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| value           | *number*        | The number in question
| unsigned        | *boolean*       | Whether unsigned or not, defaults to `false` for signed
| **@returns**    | *!Long*         | The corresponding Long value

#### Long.fromString(str, unsigned=, radix=)

Returns a Long representation of the given string, written using the specified radix.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| str             | *string*        | The textual representation of the Long
| unsigned        | *boolean &#124; number* | Whether unsigned or not, defaults to `false` for signed
| radix           | *number*        | The radix in which the text is written (2-36), defaults to 10
| **@returns**    | *!Long*         | The corresponding Long value

#### Long.isLong(obj)

Tests if the specified object is a Long.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| obj             | ***             | Object
| **@returns**    | *boolean*       |

#### Long.fromValue(val)

Converts the specified value to a Long.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| val             | *!Long &#124; number &#124; string &#124; !{low: number, high: number, unsigned: boolean}* | Value
| **@returns**    | *!Long*         |

---

#### Long.high

The high 32 bits as a signed value.

|                 |                 |
|-----------------|-----------------|
| **@type**       | *number*        |

#### Long.low

The low 32 bits as a signed value.

|                 |                 |
|-----------------|-----------------|
| **@type**       | *number*        |

#### Long.unsigned

Whether unsigned or not.

|                 |                 |
|-----------------|-----------------|
| **@type**       | *boolean*       |

#### Long:add(addend)

Returns the sum of this and the specified Long.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| addend          | *!Long &#124; number &#124; string* | Addend
| **@returns**    | *!Long*         | Sum

#### Long:band(other)

Returns the bitwise AND of this Long and the specified.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| other           | *!Long &#124; number &#124; string* | Other Long
| **@returns**    | *!Long*         |

#### Long:bnot()

Returns the bitwise NOT of this Long.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| **@returns**    | *!Long*         |

#### Long:bor(other)

Returns the bitwise OR of this Long and the specified.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| other           | *!Long &#124; number &#124; string* | Other Long
| **@returns**    | *!Long*         |

#### Long:bxor/xor(other)

Returns the bitwise XOR of this Long and the given one.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| other           | *!Long &#124; number &#124; string* | Other Long
| **@returns**    | *!Long*         |

#### Long:compare/comp(other)

Compares this Long's value with the specified's.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| other           | *!Long &#124; number &#124; string* | Other value
| **@returns**    | *number*        | 0 if they are the same, 1 if the this is greater and -1 if the given one is greater

#### Long:divide/div/__div(divisor)

Returns this Long divided by the specified.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| divisor         | *!Long &#124; number &#124; string* | Divisor
| **@returns**    | *!Long*         | Quotient

#### Long:equals/eq/__eq(other)

Tests if this Long's value equals the specified's.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| other           | *!Long &#124; number &#124; string* | Other value
| **@returns**    | *boolean*       |

#### Long:getHighBits()

Gets the high 32 bits as a signed integer.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| **@returns**    | *number*        | Signed high bits

#### Long:getHighBitsUnsigned()

Gets the high 32 bits as an unsigned integer.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| **@returns**    | *number*        | Unsigned high bits

#### Long:getLowBits()

Gets the low 32 bits as a signed integer.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| **@returns**    | *number*        | Signed low bits

#### Long:getLowBitsUnsigned()

Gets the low 32 bits as an unsigned integer.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| **@returns**    | *number*        | Unsigned low bits

#### Long:getNumBitsAbs()

Gets the number of bits needed to represent the absolute value of this Long.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| **@returns**    | *number*        |

#### Long:greaterThan/gt(other)

Tests if this Long's value is greater than the specified's.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| other           | *!Long &#124; number &#124; string* | Other value
| **@returns**    | *boolean*       |

#### Long:greaterThanOrEqual/gte(other)

Tests if this Long's value is greater than or equal the specified's.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| other           | *!Long &#124; number &#124; string* | Other value
| **@returns**    | *boolean*       |

#### Long:isEven()

Tests if this Long's value is even.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| **@returns**    | *boolean*       |

#### Long:isNegative()

Tests if this Long's value is negative.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| **@returns**    | *boolean*       |

#### Long:isOdd()

Tests if this Long's value is odd.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| **@returns**    | *boolean*       |

#### Long:isPositive()

Tests if this Long's value is positive.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| **@returns**    | *boolean*       |

#### Long:isZero()

Tests if this Long's value equals zero.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| **@returns**    | *boolean*       |

#### Long:lessThan/lt(other)

Tests if this Long's value is less than the specified's.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| other           | *!Long &#124; number &#124; string* | Other value
| **@returns**    | *boolean*       |

#### Long:lessThanOrEqual/lte(other)

Tests if this Long's value is less than or equal the specified's.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| other           | *!Long &#124; number &#124; string* | Other value
| **@returns**    | *boolean*       |

#### Long:modulo/mod/__mod(divisor)

Returns this Long modulo the specified.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| divisor         | *!Long &#124; number &#124; string* | Divisor
| **@returns**    | *!Long*         | Remainder

#### Long:multiply/mul/__mul(multiplier)

Returns the product of this and the specified Long.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| multiplier      | *!Long &#124; number &#124; string* | Multiplier
| **@returns**    | *!Long*         | Product

#### Long:negate/neg/__unm()

Negates this Long's value.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| **@returns**    | *!Long*         | Negated Long

#### Long:notEquals/neq(other)

Tests if this Long's value differs from the specified's.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| other           | *!Long &#124; number &#124; string* | Other value
| **@returns**    | *boolean*       |

#### Long:shiftLeft/shl(numBits)

Returns this Long with bits shifted to the left by the given amount.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| numBits         | *number &#124; !Long* | Number of bits
| **@returns**    | *!Long*         | Shifted Long

#### Long:shiftRight/shr(numBits)

Returns this Long with bits arithmetically shifted to the right by the given amount.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| numBits         | *number &#124; !Long* | Number of bits
| **@returns**    | *!Long*         | Shifted Long

#### Long:shiftRightUnsigned/shru(numBits)

Returns this Long with bits logically shifted to the right by the given amount.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| numBits         | *number &#124; !Long* | Number of bits
| **@returns**    | *!Long*         | Shifted Long

#### Long:subtract/sub/__sub(subtrahend)

Returns the difference of this and the specified Long.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| subtrahend      | *!Long &#124; number &#124; string* | Subtrahend
| **@returns**    | *!Long*         | Difference

#### Long:toInt()

Converts the Long to a 32 bit integer, assuming it is a 32 bit integer.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| **@returns**    | *number*        |

#### Long:toNumber()

Converts the Long to a the nearest floating-point representation of this value (double, 53 bit mantissa).

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| **@returns**    | *number*        |

#### Long:toSigned()

Converts this Long to signed.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| **@returns**    | *!Long*         | Signed long

#### Long:toString(radix=)

Converts the Long to a string written in the specified radix.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| radix           | *number*        | Radix (2-36), defaults to 10
| **@returns**    | *string*        |
| **@throws**     | *RangeError*    | If `radix` is out of range

#### Long:toUnsigned()

Converts this Long to unsigned.

| Parameter       | Type            | Description
|-----------------|-----------------|---------------
| **@returns**    | *!Long*         | Unsigned long 

## Testing

### Testing Locally

```sh
$ busted -v
●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
39 successes / 0 failures / 0 errors / 0 pending : 0.068103 seconds
```

### Testing with a Specific Lua Version

Various Dockerfiles are made available in the root directory to provide a specific Lua VM for the test suite:

* `Test-Lua5.1.Dockerfile`
* `Test-Lua5.2.Dockerfile`
* `Test-Lua5.3.Dockerfile`

```sh
$ docker build -f Test-Lua5.1.Dockerfile -t test .
$ docker run -it test busted -v --defer-print

41 successes / 0 failures / 0 errors / 0 pending : 2.41141 seconds
```
