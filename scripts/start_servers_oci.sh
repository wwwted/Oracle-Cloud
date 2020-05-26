#!/bin/bash
#
# Script to start hosts/databases
#
# TedW
#

priv_key="/home/ted/OCI/id_rsa"
prefix=$1
[ $# -ne 1 ] && echo "Wrong number of arguments, Usage: $0 <prefix name for nodes>" && exit
[ -z "$prefix" ] && echo "You must add a prefix string, Usage: $0 <prefix name for nodes>" && exit

id_list=`cat "/tmp/oci/${prefix}NodesStarted.ids"`
#echo $id_list

for id in $id_list
do
   #echo $id
   oci compute instance action --action START --instance-id $id --wait-for-state "RUNNING"
done

for id in $id_list
do
   #echo $id
   ip=`oci compute instance list-vnics --query data[0].'"public-ip"' --raw-output --instance-id $id | tr -d '"'`
   ip_list="$ip $ip_list"
   #echo $ip_list
done

# Need to wait for sshd to start ...
for ip in $ip_list
do
   #echo $ip
   state=$( ssh -q -o "ConnectTimeout=5" -o "StrictHostKeyChecking=no" -i $priv_key opc@$ip 'whoami' )
   #echo $state
   while [ "$state" != "opc" ]
   do
      echo "SSH Daemon not up(state=$state), sleep some more ...."
      state=$( ssh -q -o "ConnectTimeout=5" -o "StrictHostKeyChecking=no" -i $priv_key opc@$ip 'whoami' )
      sleep 3
   done
done

# Start MySQL Servers
echo "Starting MySQL Servers"
for ip in $ip_list
do
   ssh -o "ConnectTimeout=10" -o "StrictHostKeyChecking=no" -f -i $priv_key opc@$ip '/home/opc/refresh.sh' >/dev/null 2>/dev/null
done

