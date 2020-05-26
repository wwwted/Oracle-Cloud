#!/bin/bash
#
# Script to list status of hosts
#
# TedW
#

prefix=$1
[ $# -ne 1 ] && echo "Wrong number of arguments, Usage: $0 <prefix for nodes>" && exit
[ -z "$prefix" ] && echo "You must add a prefix string, Usage: $0 <prefix for nodes>" && exit

id_list=`cat "/tmp/oci/${prefix}NodesStarted.ids"`
#echo $id_list

for id in $id_list
do
   # echo $id
   oci compute instance get --query data.['"display-name"','"lifecycle-state"'] --raw-output --instance-id $id
done

