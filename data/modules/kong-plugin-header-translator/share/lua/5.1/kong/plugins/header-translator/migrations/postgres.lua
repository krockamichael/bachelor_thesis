return {
    {
        name = "2019-04-09-170000_init_header_translator",
        up = [[
              CREATE TABLE IF NOT EXISTS header_translator_dictionary(
                input_header_name text,
                input_header_value text,
                output_header_name text,
                output_header_value text,
                PRIMARY KEY (input_header_name, input_header_value, output_header_name)
              );
            ]],
        down = [[
              DROP TABLE header_translator_dictionary;
            ]]
    }
}
