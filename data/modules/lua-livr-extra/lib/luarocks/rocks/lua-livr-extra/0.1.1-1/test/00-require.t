#!/usr/bin/env lua

require 'Test.More'

plan(8)

if not require_ok 'LIVR.Rules.Extra' then
    BAIL_OUT "no lib"
end

local m = require 'LIVR.Rules.Extra'
type_ok( m, 'table', 'module' )
is( m, package.loaded['LIVR.Rules.Extra'], 'package.loaded' )

is( m._NAME, 'LIVR.Rules.Extra', "_NAME" )
like( m._COPYRIGHT, 'Perrad', "_COPYRIGHT" )
like( m._DESCRIPTION, 'LIVR rules', "_DESCRIPTION" )
type_ok( m._VERSION, 'string', "_VERSION" )
like( m._VERSION, '^%d%.%d%.%d$' )

