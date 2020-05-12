# PokerHand-eval

[![Build Status](https://travis-ci.org/AlberTajuelo/pokerhand-eval.svg)](https://travis-ci.org/AlberTajuelo/pokerhand-eval)
[![codecov](https://codecov.io/gh/AlberTajuelo/pokerhand-eval/branch/master/graph/badge.svg)](https://codecov.io/gh/AlberTajuelo/pokerhand-eval)
[![License](https://img.shields.io/badge/License-MIT-brightgreen.svg)](LICENSE)

Poker Texas Hold'em Hand Evaluator using pure Lua.

## Contents

* [Overview](#overview)
* [Origin](#origin)
* [Requirements](#requirements)
* [Basic Usage](#basic-usage)
* [Documentation](#documentation)
* [Development](#development)
* [References](#references)

## Overview

This is a pure Lua library to calculate the rank of the best [Texas Holdem] hand out of 5, 6, or 7 cards. It does not run the board for you, or calculate winning percentage, EV, or anything like that. But if you give it two hands and the same board, you will be able to tell which hand wins.

Also there is a two-card ranking/percentile algorithm (Credit to Zach Wissner-Gross).

This is a Lua port from the [python library](https://github.com/aliang/pokerhand-eval).

## Origin

This repository is based on Ivan Ribeiro (@irr) work: https://github.com/irr/lua-pokerhand-eval

## Requirements

Lua version required: 5.1 or 5.2.

## Basic Usage

If using LuaRocks:
```
luarocks install pokerhand-eval
```

Otherwise, download <https://github.com/AlberTajuelo/pokerhand-eval/zipball/master>.

Alternately, if using GIT:

```
git clone git://github.com/AlberTajuelo/pokerhand-eval.git

cd pokerhand-eval 

luarocks make
```

Calculate Hand winning percentile without board cards:

```lua

    card = require "holdem.card"
    lookup = require "holdem.lookup"
    analysis = require "holdem.analysis"

    hand = { card.Card(2, 1), card.Card(2, 2) }
    board = {}
    rank, percentile = analysis.evaluate(hand, board)
    print(rank, percentile)
    -- Output: nil	0.52337858220211
    -- For 2 cards, rank will be nil and you must use percentile

```

Calculate hand winning percentile with three board cards:

```lua

    card = require "holdem.card"
    lookup = require "holdem.lookup"
    analysis = require "holdem.analysis"

    hand = { card.Card(2, 1), card.Card(2, 2) }
    board = { card.Card(10, 2), card.Card(14, 2), card.Card(13, 2), card.Card(7, 2) }
    rank, percentile = analysis.evaluate(hand, board)
    print(rank, percentile)
    -- Output: 420  0.6792270531401
    -- ps: less rank is better

```

## Documentation

### Card Rank

This table represents given a card rank what index is assigned. Rank is 2-14 representing 2-A (Ace).

| Card Rank | Index | Symbol |
|-----------|-------|--------|
| 2         | 2     | 2      |
| 3         | 3     | 3      |
| 4         | 4     | 4      |
| 5         | 5     | 5      |
| 6         | 6     | 6      |
| 7         | 7     | 7      |
| 8         | 8     | 8      |
| 9         | 9     | 9      |
| 10        | 10    | T      |
| Jack      | 11    | J      |
| Queen     | 12    | Q      |
| King      | 13    | K      |
| Ace       | 14    | A      |

### Card Suit

This table represents given a card suit what index is assigned. Suit is 1-4 representing in given order Spades, Hearts, Diamonds and Clubs.

| Card Suit    | Index | Symbol |
|--------------|-------|--------|
| Spades (♠)   | 1     | S      |
| Hearts (♥)   | 2     | H      |
| Diamonds (♦) | 3     | D      |
| Clubs (♣)    | 4     | C      |

### Card Constructor

The Card constructor accepts two arguments, rank, and suit.

```lua

    card = require "holdem.card"

    aceOfSpades = card.Card(14, 1)
    twoOfDiamonds = card.Card(2, 3)

    -- or

    aceOfSpades = card.Card("AS")
    twoOfDiamonds = card.Card("2D")

```

## Development

PokerHand-eval is currently in development.

WARNING: Not all corner cases have been tested and documented.

## References

The algorithm for 5 cards is just a port of this [algorithm](http://www.suffecool.net/poker/evaluator.html).

Six and seven card evaluators using a very similar card representation and applying some of the same ideas with prime numbers. The idea was to strike a balance between lookup table size and speed.

You can search for more info using following references:

* [Texas Holdem](http://en.wikipedia.org/wiki/Texas_hold_%27em)
* [BitOp-lua](https://github.com/AlberTajuelo/bitop-lua)
* [underscore-dot-lua](https://github.com/AlberTajuelo/underscore-dot-lua)
