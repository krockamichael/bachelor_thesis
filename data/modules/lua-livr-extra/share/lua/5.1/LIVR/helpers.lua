
--
-- lua-LIVR : <https://fperrad.frama.io/lua-LIVR/>
--

local _ENV = nil

local primitive_type = {
        boolean = true,
        number = true,
        string = true,
}

local string_number_type = {
        number = true,
        string = true,
}

local number_boolean_type = {
        boolean = true,
        number = true,
}

return {
    primitive_type = primitive_type,
    string_number_type = string_number_type,
    number_boolean_type = number_boolean_type,
}
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
