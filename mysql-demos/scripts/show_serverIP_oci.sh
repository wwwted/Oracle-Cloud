#!/bin/bash
#
# Script to show IP of hosts
#
# TedW
#

prefix=$1
[ $# -ne 1 ] && echo "Wrong number of arguments, Usage: $0 <prefix name for nodes>" && exit
[ -z "$prefix" ] && echo "You must add a prefix string, Usage: $0 <prefix name for nodes>" && exit

cat "/tmp/oci/${prefix}Nodes.txt"

