#!/bin/bash

LUADB_ROOT_PATH=../../
LUA_BIN=$LUADB_ROOT_PATH/_build/dependencies_bin/bin/lua

export LUA_CPATH="$LUADB_ROOT_PATH/_build/dependencies_install/lib/lua/?/?.so;$LUADB_ROOT_PATH/_build/dependencies_install/lib/lua/?.so"
export LUA_PATH="$LUADB_ROOT_PATH/_build/dependencies_install/lib/lua/?/init.lua;$LUADB_ROOT_PATH/_build/dependencies_install/lib/lua/?.lua"
export LUA_PATH="$LUA_PATH;$LUADB_ROOT_PATH/src/?.lua;$LUADB_ROOT_PATH/src/?/init.lua"

# for calculating the number of nodes in graphs, but not used since number of nodes in graphs is written at the end of every json file
#
#
#
# array=$($LUA_BIN extract_dir.lua "modules/$1") # store output of extract_dir.lua into variable (basically text which is printed to console)
# array=( $array ) # create array from variable, delimiter is whitespace

# result=()

# for i in "${array[@]}"
# do
# 	if [[ $i == *".number_of_nodes"* ]]; then # if array element containts *.number_of_nodes then cut the * and put it into a new array --> number of nodes in a graph
# 		result+=(${i%.number_of_nodes}) # will contain the number of nodes for a each graph
# 	fi
# done

# echo ${result[@]} # print all elements of an array to serve as input for start_luadb_in_all_packages.sh script

$LUA_BIN extract_dir.lua "modules/$1"
