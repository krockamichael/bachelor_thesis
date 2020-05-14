#!/bin/bash

# number_of_graphs=0
# total_number_of_nodes=0
# all_nodes=()

for DIRECTORY in modules/* ; do
   PACKAGE=$(basename $DIRECTORY)

   luarocks --tree "modules/$PACKAGE" show "$PACKAGE" > /dev/null 2>&1
   if [ $? -eq 0 ]; then
      echo "Testing $PACKAGE"
      ./run_in_single_package.sh "$PACKAGE"

      # temp_array=$(./run_in_single_package.sh "$PACKAGE") #save output (number of nodes in each graph) to variable temp_array
      # # example of temp_array is "17 26 8 2 17" --> IMPORTANT, this is a single variable not an array!!

      # temp_array=( $temp_array ) # create an array from variable
      # # note: echo ${temp_array[@]} to print the array members

      # all_nodes=(${all_nodes[@]} ${temp_array[@]}) # remember all the graphs and the number of their nodes

      # # echo ${temp_array[@]}
      # unset temp_array

   else
      echo "WARN: $PACKAGE not installed" >&2
   fi
done

# # ${#all_nodes[@]} --> length of the array
# number_of_graphs=${#all_nodes[@]}

# # add up the number of nodes for all graphs
# for i in "${all_nodes[@]}"
# do
# 	total_number_of_nodes=`expr $total_number_of_nodes + $i`
# done

# echo "graphs: " $number_of_graphs " nodes: " total_number_of_nodes

# all_nodes_text=~/luadb/etc/luarocks_test/text.txt
# echo ${all_nodes[@]} >all_nodes_text
