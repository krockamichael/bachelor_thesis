---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2011, Peter J Billam      --
--                       www.pjb.com.au                            --
--                                                                 --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------

local M = {} -- public interface
M.Version     = '1.3' -- readline erases final space if tab-completion
M.VersionDate = '31oct2013'

-------------------- private utility functions -------------------
local function warn(str) io.stderr:write(str,'\n') end
local function die(str) io.stderr:write(str,'\n') ;  os.exit(1) end
local function qw(s)  -- t = qw[[ foo  bar  baz ]]
    local t = {} ; for x in s:gmatch("%S+") do t[#t+1] = x end ; return t
end
local function deepcopy(object)  -- http://lua-users.org/wiki/CopyTable
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end
local function sorted_keys(t)
	local a = {}
	for k,v in pairs(t) do a[#a+1] = k end
	table.sort(a)
	return  a
end
local function touch(fn)
    local f=io.open(fn,'r') -- or check if posix.stat(path) returns non-nil
    if f then
		f:close(); return true
	else
    	f=io.open(fn,'w')
    	if f then
			f:write(""); f:close(); return true
		else
			return false
		end
	end
end
local function homedir(user)
	if not user and os.getenv('HOME') then return os.getenv('HOME') end
	local P = nil
    pcall(function() P = require 'posix' ; end )
    if type(P) == 'table' then  -- we have posix
		if not user then user = P.getpid('euid') end
		return P.getpasswd(user, 'dir') or '/tmp'
	end
	warn('readline: HOME not set and luaposix not installed; using /tmp')
	return '/tmp/'
end
local function tilde_expand(filename)
    if string.match(filename, '^~') then
        local user = string.match(filename, '^~(%a+)/')
        local home = homedir(user)
        filename = string.gsub(filename, '^~%a*', home)
    end
    return filename
end


---------------- from Lua Programming Gems p. 331 ----------------
local require, table = require, table -- save the used globals
local aux, prv = {}, {} -- auxiliary & private C function tables
local initialise = require 'C-readline'
initialise(aux, prv, M) -- initialise the C lib with aux,prv & module tables

------------------------ public functions ----------------------

prv.using_history()
local Option = {   -- the default options
	auto_add   = true,
	completion = true,
	histfile   = '~/.rl_lua_history',
	ignoredups = true,
	keeplines  = 500,
	minlength  = 2,
}
local PreviousLine = ''

function M.read_history ()
	local histfile = tilde_expand( Option['histfile'] )
	return prv.read_history ( histfile )
end

M.read_history( Option['histfile'] )
local OldHistoryLength = prv.history_length()
-- print('OldHistoryLength='..tostring(OldHistoryLength))

------------------------ public functions ----------------------

function M.set_options ( tbl )
	if tbl == nil then return end
	if type(tbl) ~= 'table' then
		die('set_options: argument must be a table, not '..type(tbl))
	end
	local old_options = deepcopy(Option)
	for k,v in pairs(tbl) do
		if k == 'completion' then
			if type(v) ~= 'boolean' then
				die('set_options: completion must be boolean, not '..type(v))
			end
			prv.tabcompletion ( v )
			Option[k] = v
		elseif k == 'histfile' then
			if v ~= Option['histfile'] then
				if type(v) ~= 'string' then
					die('set_options: histfile must be string, not '..type(v))
				end
				Option[k] = v
				prv.clear_history()
				local rc = M.read_history( Option['histfile'] )  -- 1.2
			end
		elseif k == 'keeplines' or k == 'minlength' then
			if type(v) ~= 'number' then
				die('set_options: '..k..' must be number, not '..type(v))
			end
			Option[k] = v
		elseif k == 'ignoredups' or k == 'auto_add' then
			if type(v) ~= 'boolean' then
				die('set_options: '..k..' must be boolean, not '..type(v))
			end
			Option[k] = v
		else
			die('set_options: unrecognised option '..tostring(k))
		end
	end
	return old_options
end

function M.readline ( prompt )
	prompt = prompt or ''
	if type(prompt) ~= 'string' then
		die('readline: prompt must be a string, not '..type(prompt))
	end
	local line = prv.readline ( prompt )   -- might be nil if EOF...
	if Option['auto_add'] and line and line~=''
	  and string.len(line)>=Option['minlength'] then
		if line ~= PreviousLine or not Option['ignoredups'] then
			prv.add_history(line)
			PreviousLine = line
		end
	end
	if Option['completion'] then
		return string.gsub(line, ' $', '')  -- 1.3
	else
		return line
	end
end

function M.add_history ( str )
	if type(str) ~= 'string' then
		die('add_history: str must be a string, not '..type(str))
	end
	return prv.add_history ( str )
end

function M.save_history ( )
	if type(Option['histfile']) ~= 'string' then
		die('save_history: histfile must be a string, not '
		  .. type(Option['histfile']))
	end
	if Option['histfile'] == '' then return end
	local histfile = tilde_expand( Option['histfile'] )
	if type(Option['keeplines']) ~= 'number' then
		die('save_history: keeplines must be a number, not '
		  .. type(Option['keeplines']))
	end
	local n = prv.history_length()
	if n > OldHistoryLength then
		touch(histfile)
		local rc = prv.append_history(n-OldHistoryLength, histfile)
		if rc ~= 0 then warn('append_history: '..prv.strerror(rc)) end
		rc = prv.history_truncate_file ( histfile, Option['keeplines'] )
		if rc ~= 0 then warn('history_truncate_file: '..prv.strerror(rc)) end
	end
	return
end

function M.strerror ( errnum )
	return prv.strerror(tonumber(errnum))
end

return M

--[[

=pod

=head1 NAME

C<readline> - a simple interface to the I<readline> and I<history> libraries

=head1 SYNOPSIS

 local RL = require 'readline'
 -- see: man readline
 RL.set_options{ keeplines=1000, histfile='~/.synopsis_history' }
 local str = RL.readline('Please enter some filename: ')
 local save_options = RL.set_options{ completion=false }
 str = RL.readline('Please type a line which can include Tabs: ')
 RL.set_option(save_options)
 str = RL.readline('Now tab-filename-completion is working again: ')
 ...
 PL.save_history() ; os.exit()

=head1 DESCRIPTION

This Lua module offers a simple calling interface
to the GNU Readline/History Library.

The function I<readline()> is a wrapper, which invokes the GNU
I<readline>, adds the line to the end of the History List,
and then returns the line.
Usually you call I<save_history()> before the program exits,
so that the History List is saved to the I<histfile>.

Various options can be changed using the I<set_options{}> function.

The user can configure the GNU Readline (e.g. I<vi> or I<emacs> keystrokes ?)
with their individual I<~/.inputrc> file,
see the I<INITIALIZATION FILE> section of I<man readline>.

By default, the GNU I<readline> library dialogues with the user
by reading from I<stdin> and writing to I<stdout>;
This fits badly with applications that want to
use I<stdin> and I<stdout> to input and output data.
Therefore, this Lua module dialogues with the user on the controlling-terminal
of the process (typically I</dev/tty>) as returned by I<ctermid()>.

=head1 FUNCTIONS

=head3 RL.set_options{ histfile='~/.myapp_history', keeplines=100 }

Returns the old options, so they can be restored later.
The I<auto_add> option controls whether the line entered will be
added to the History List,
The default options are:

 auto_add   = true,
 histfile   = '~/.rl_lua_history',
 keeplines  = 500,
 completion = true,
 ignoredups = true,
 minlength  = 2,

Lines shorter than the I<minlength> option will not be put on the History List.
Tilde expansion is performed on the I<histfile> option.
The I<histfile> option must be a string, so don't set it to I<nil>,
if you want to avoid reading or writing your History List to the filesystem,
set I<histfile> to the empty string.
If you want no history behaviour (Up or Down arrows etc.) at all, then set

 set_options{ histfile='', auto_add=false, }

=head3 RL.readline( prompt )

Displays the I<prompt> and returns the text of the line the user enters.
A blank line returns the empty string.
If EOF is encountered while reading a line, and the line is empty,
I<nil> is returned;
if an EOF is read with a non-empty line, it is treated as a newline.

If the I<auto_add> option is I<true> (which is the default),
the line the user enters will be added to the History List,
unless it's shorter than I<minlength>,
or it's the same as the previous line and the I<ignoredups> option is set.

=head3 RL.save_history()

Normally, you should call this function before your program exits.
It saves the lines the user has entered onto the end of the I<histfile> file.
Then if necessary it truncates lines off the beginning of the I<histfile>
to confine it to I<keeplines> long.

=head3 RL.add_history( line )

Adds the I<line> to the History List.
You'll only need this function if you want to assume complete control
over the strings that get added, in which case you:

 RL.set_options{ auto_add=false, }

and then after calling I<readline(prompt)>
you can process the I<line> as you wish
and call I<add_history(line)> if appropriate.

=head1 DOWNLOAD

This module is available as a LuaRock in
luarocks.org/repositories/rocks
so you should be able to install it with the command:

 $ su
 Password:
 # luarocks install readline

or:

 # luarocks install http://www.pjb.com.au/comp/lua/readline-1.3-0.rockspec

It depends on the I<readline> library and its header-files;
for example, on Debian you may also need:

 # aptitude install libreadline6 libreadline6-dev

=head1 CHANGES

 20131031 1.3 readline erases final space if tab-completion is used
 20131020 1.2 set_options{histfile='~/d'} expands the tilde
 20130921 1.1 uses ctermid() (usually /dev/tty) to dialogue with the user
 20130918 1.0 first working version 

=head1 AUTHOR

Peter Billam, 
http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

=over 3

 man readline
 http://www.gnu.org/s/readline
 http://cnswww.cns.cwru.edu/php/chet/readline/rltop.html
 http://cnswww.cns.cwru.edu/php/chet/readline/readline.html
 http://cnswww.cns.cwru.edu/php/chet/readline/history.html
 /usr/share/readline/inputrc
 ~/.inputrc
 http://luarocks.org/repositories/rocks/index.html#luaposix
 http://www.pjb.com.au
 http://www.pjb.com.au/comp/index.html#lua

=back

=cut
]]
