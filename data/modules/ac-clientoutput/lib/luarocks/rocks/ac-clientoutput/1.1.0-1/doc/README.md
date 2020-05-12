AC-ClientOutput
===============

This library allows you to format output string and tables for clients of your AssaultCube lua server.


Usage
-----

You can install this library with `luarocks install ac-clientoutput`. <br />
If you choose to download the source files instead you must add the path to the `AC-ClientOutput/src` folder to your `package.path`.

Then you can include the `ClientOutputFactory` with `require "AC-ClientOutput.ClientOutputFactory"`.


### ClientOutputFactory ###

The ClientOutputFactory can be used to create ClientOutputString's and ClientOutputTable's. <br />
To use this class you must first get the current instance with `ClientOutputFactory.getInstance()`

#### Configuration ####

Use `ClientOutputFactory.getInstance():configure(<options>)` to configure the ClientOutputFactory. <br />
The available options are:

| Option Name         | Description                                           | Allowed values                |
|---------------------|-------------------------------------------------------|-------------------------------|
| fontConfigFileName  | The name of the font config to use                    | "FontDefault" (default)       |
| maximumLineWidth    | The maximum line width in 3x pixels                   | int (Default: 3900)           |
| newLineIndent       | The default new line indent                           | string (Default: "")          |
| lineSplitCharacters | The default characters at which lines should be split | lua expression (Default: " ") |


#### Creating a ClientOutputString ####

Use `ClientOutputFactory.getInstance():getClientOutputString(<string>)` to create a new ClientOutputString. <br />

Next you may configure the created ClientOutputString with the `configure(<options>)` method.
The available options are:

| Option Name         | Description               | Allowed values                                         |
|---------------------|---------------------------|--------------------------------------------------------|
| newLineIndent       | The new line indent       | string (Default: ClientOutputFactory's value)          |
| lineSplitCharacters | The line split characters | lua expression (Default: ClientOutputFactory's value)  |
| numberOfTabs        | The number of tabs to use | int (Default: ClientOutputFactory's width / tab width) |

Note: The number of tabs is internally converted to a pixel width.

Finally you can fetch the generated output rows with `getOutputRows()`.


#### Creating a ClientOutputTable ####

Use `ClientOutputFactory.getInstance():getClientOutputTable(<table>)` to create a new ClientOutputTable. <br />
The ClientOutputTable requires a table in which all rows have the same number of fields. You may however add tables as row fields to realize any sort of column spans.

The ClientOutputTable provides the same configuration settings as the ClientOutputString, additionally you can configure these options:

| Option Name | Description                          | Allowed values                                         |
|-------------|--------------------------------------|--------------------------------------------------------|
| rows        | Set the options for an entire row    | Same as ClientOutputTable configurations (Default: {}) |
| columns     | Set the options for an entire column | Same as ClientOutputTable configurations (Default: {}) |
| fields      | Set the options for specific fields  | Same as ClientOutputTable configurations (Default: {}) |

Note: The `fields` configuration expects a table in the format `{ [y] = { [x] = { configuration } } }`.

The configurations are applied as in the order above which means `fields` overwrites `columns`, `columns` overwrites `rows` and `rows` overwrites the ClientOutputTable's own configuration. <br />
By default every sub field gets the same configuration as the ClientOutputTable except for the number of tabs which is calculated individually.

Finally you can fetch the generated output rows with `getOutputRows()`.
