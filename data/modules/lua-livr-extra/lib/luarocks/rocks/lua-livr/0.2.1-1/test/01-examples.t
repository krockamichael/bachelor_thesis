#!/usr/bin/env lua

require 'Test.More'

plan(5)

local livr = require 'LIVR.Validator'
local validator, data

validator = livr.new{
    name      = 'required',
    email     = { 'required', 'email' },
    gender    = { one_of = { 'male', 'female' } },
    phone     = { max_length = 10 },
    password  = { 'required', { min_length = 10 } },
    password2 = { equal_to_field = 'password' }
}
data = validator:validate{
    name = 'John',
    email = 'john@mail.com',
    gender = 'male',
    phone = '+22221212',
    password = 'mypassword1',
    password2 = 'mypassword1'
}
ok( data, 'registration form' )

validator = livr.new{
    name = 'required',
    phone = { max_length = 10 },
    address = { nested_object = {
        city = 'required',
        zip = { 'required', 'positive_integer' }
    }}
}
data = validator:validate{
    name = 'aaaa',
    phone = '+823832',
    address = {
        city = 'Kyiv',
        zip = 1232
    }
}
ok( data, 'nested object' )

validator = livr.new{
    order_id = { 'required', 'positive_integer' },
    product_ids = {
        list_of = { 'required',  'positive_integer' }
    }
}
data = validator:validate{
    order_id = 10455,
    product_ids = { 3455, 3456, 3566 }
}
ok( data, 'simple order list' )

validator = livr.new{
    order_id = { 'required', 'positive_integer' },
    products = { 'not_empty_list', { list_of_objects = {
        product_id = { 'required', 'positive_integer' },
        quantity = { 'required', 'positive_integer' }
    }}}
}
data = validator:validate{
    order_id = 10345,
    products = {{
        product_id = 3455,
        quantity = 2
    }, {
        product_id = 3456,
        quantity = 3
    }}
}
ok( data, 'list order with products objects' )

validator = livr.new{
    order_id = { 'required', 'positive_integer' },
    products = { 'required', { list_of_different_objects = {
        'product_type', {
            material = {
                product_type = 'required',
                material_id = { 'required', 'positive_integer' },
                quantity = { 'required', { min_number = 1 } },
                warehouse_id = 'positive_integer'
            },
            service = {
                product_type = 'required',
                name = { 'required', { max_length = 20 } }
            }
        }
    }}}
}
data = validator:validate{
    order_id = 10455,
    products = {{
        product_type = 'material',
        material_id = 345,
        quantity =  5,
        warehouse_id = 24
    }, {
        product_type = 'service',
        name = 'Clean filter'
    }}
}
ok( data, 'registration form' )

