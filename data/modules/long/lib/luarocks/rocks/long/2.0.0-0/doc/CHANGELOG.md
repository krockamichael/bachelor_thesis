## [2.0.0] - 2019-06-04
### Changed:
- [#33](https://github.com/BixData/lua-long/issues/33) Remove middleclass dependency

## [1.0.3-1] - 2019-06-04
### Fixed:
- [#30](https://github.com/BixData/lua-long/issues/30) gzip extraction error when installing with luarocks

## [1.0.3-0] - 2017-12-05
### Added:
- Port `band`, `bor` and `bxor` bitwise functions

## [1.0.2-0] - 2017-11-26
### Added:
- Implement `__add` Lua metamethod

## [1.0.1-0] - 2017-11-26
### Added:
- Implement `__div`, `__le`, `__lt`, `__mod`, `__mul`, `__sub`, and `__unm` Lua metamethods

## [1.0.0-0] - 2017-11-24
### Added:
- Port `add`, `bnot`, `compare`, `divide`, `equals`, `fromBits`, `fromInt`, `fromNumber`, `fromValue`, `greaterThan`, `greaterThanOrEqual`, `isEven`, `isLong`, `isNegative`, `isOdd`, `isZero`, `lessThan`, `lessThanOrEqual`, `modulo`, `multiply`, `negate`, `shiftLeft`, `shiftRight`, `shiftRightUnsigned`, `subtract`, `toBytes`, `toInt`, `toNumber`, `toSigned`, and `toUnsigned` functions
- Partially port `toString` for radix=16 (only supports positive numbers so far)
- Implement `__eq` and `__tostring` Lua metamethods
- LuaRocks packaging

<small>(formatted per [keepachangelog-1.1.0](http://keepachangelog.com/en/1.0.0/))</small>
