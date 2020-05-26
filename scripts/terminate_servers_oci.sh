#!/bin/bash
#
# Script to terminate hosts
#
# TedW
#

prefix=$1
[ $# -ne 1 ] && echo "Wrong number of arguments, Usage: $0 <prefix name for nodes>" && exit
[ -z "$prefix" ] && echo "You must add a prefix string, Usage: $0 <prefix name for nodes>" && exit

id_list=`cat "/tmp/oci/${prefix}NodesStarted.ids"`
#echo $id_list

for id in $id_list
do
   echo "terminating instance $id"
   oci compute instance terminate --force --instance-id $id
done

read -p "Do you to remove status files (y/n)? " input
if [ $input = "y" ] 
then 
   rm -f "/tmp/oci/${prefix}NodesStarted.ids"
   rm -f "/tmp/oci/${prefix}Nodes.txt"
fi

