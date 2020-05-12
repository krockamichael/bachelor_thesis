
# LIVR

---

# Reference

## Class functions & members

#### new( rules [, is_auto_trim] )

Creates an *validator* instance from the table `rules`.
When the boolean `is_auto_trim` is missing, the global `default_auto_trim` is used.

#### register_default_rules( rules )

Registers additional `rules`. `rules` is a table, where keys are string *rule name*
and values are function *rule builder*.

#### register_aliased_default_rule( alias )

Registers an aliased rule.
`alias` is a table with:

- a required key `name`, the associated value is a string
- a required key `rules`, the associated value is a table or a string
- an optional key `error`, the associated value is a string

#### default_rules

global table containing all default rule_builders.

#### default_auto_trim

global boolean, its default value is `false`.

## Instance methods

#### validate( input )

Validates the table user `input`.
On success returns a table which contains only data that has described validation rules.
On error returns `nil` and a table which contains all errors.

#### register_rules( rules )

Registers additional `rules`. `rules` is a table, where keys are string *rule name*
and values are function *rule builder*.

#### register_aliased_rule( alias )

Registers an aliased rule.
`alias` is a table with:

- a required key `name`, the associated value is a string
- a required key `rules`, the associated value is a table or a string
- an optional key `error`, the associated value is a string

#### get_rules()

Returns a table containing all rule_builders for the validator.


# Examples

```lua
local livr = require 'LIVR.Validator'

-- Common usage
livr.default_auto_trim = true

local validator = livr.new{
    name      = 'required',
    email     = { 'required', 'email' },
    gender    = { one_of = { 'male', 'female' } },
    phone     = { max_length = 10 },
    password  = { 'required', { min_length = 10} },
    password2 = { equal_to_field = 'password' }
}

local valid_data, errors = validator:validate(user_data)
if valid_data then
    save_user(valid_data)
end

-- You can use modifiers separately or can combine them with validation:
local validator = livr.new{
    email = { 'required', 'trim', 'email', 'to_lc' }
}

-- Feel free to register your own rules
-- You can use aliases(preferable, syntax covered by the specification) for a lot of cases:

local validator = livr.new{
    password = { 'required', 'strong_password' }
}

validator:register_aliased_rule{
    name  = 'strong_password',
    rules = { min_length = 6 },
    error = 'WEAK_PASSWORD'
}

-- or you can write more sophisticated rules directly

local validator = livr.new{
    password = { 'required', 'strong_password' }
}

validator:register_rules{
    strong_password = function ()
        return function (value)
            if value ~= nil and value ~= '' then
                if type(value) ~= 'string' then
                    return value, 'FORMAT_ERROR'
                end
                if #value < 6 then
                    return value, 'WEAK_PASSWORD'
                end
            end
            return value
        end
    end
}
```

