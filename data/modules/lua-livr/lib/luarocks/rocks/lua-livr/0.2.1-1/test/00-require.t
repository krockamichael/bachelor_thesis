#!/usr/bin/env lua

require 'Test.More'

plan(24)

if not require_ok 'LIVR.Validator' then
    BAIL_OUT "no lib"
end

local m = require 'LIVR.Validator'
type_ok( m, 'table', 'module' )
is( m, package.loaded['LIVR.Validator'], 'package.loaded' )

type_ok( m.default_rules, 'table', 'default_rules' )
type_ok( m.default_auto_trim, 'boolean', 'default_auto_trim' )
is( m.default_auto_trim, false, 'default_auto_trim' )
type_ok( m.new, 'function', 'new' )
type_ok( m.register_default_rules, 'function', 'register_default_rules' )
type_ok( m.register_aliased_default_rule, 'function', 'register_aliased_default_rule' )

local o = m.new{}
type_ok( o, 'table', 'instance' )
type_ok( o.validate, 'function', 'meth validate' )
type_ok( o.register_rules, 'function', 'meth register_rules' )
type_ok( o.register_aliased_rule, 'function', 'meth register_aliased_rule' )
type_ok( o.get_rules, 'function', 'meth get_rules' )

is( m._NAME, 'LIVR.Validator', "_NAME" )
like( m._COPYRIGHT, 'Perrad', "_COPYRIGHT" )
like( m._DESCRIPTION, 'validator supporting LIVR', "_DESCRIPTION" )
type_ok( m._VERSION, 'string', "_VERSION" )
like( m._VERSION, '^%d%.%d%.%d$' )

local h = require 'LIVR.helpers'
type_ok( h, 'table', 'module' )
is( h, package.loaded['LIVR.helpers'], 'package.loaded' )

type_ok( h.primitive_type, 'table', 'primitive_type' )
type_ok( h.string_number_type, 'table', 'string_number_type' )
type_ok( h.number_boolean_type, 'table', 'number_boolean_type' )
