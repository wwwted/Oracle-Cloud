#!/bin/bash
#
# Script to create instance and start a MySQL Server
#
# Need to use a custom image that have MySQL binaries and scripts to install/start MySQL
# Image below is a normal OL 7.7  with no security feature enabled + have the 
# correct script (refresh.sh) in root folder (/home/opc) and binaries and links setup.
# 
# Structure should be:
# /home/opc/
#           setenv
#           refresh.sh
#           my.cnf
#           mysql  -> link to mysql binaries
#           router -> link to router binaries
#           shell  -> link to shell binaries
#
# TedW
#

ad="YOiV:EU-FRANKFURT-1-AD-1"
comp_id="ocid1.compartment.oc1..aaaaaaaadq36rajhvw6h7vc5wlzzzeja6w33tpo4bxo7yfh7axoe4gdxyn7a"
shape="VM.Standard2.1" # Intel 2GHz, 2.1 - 2.24 avaialble
#shape="VM.Standard.B1.1" # Intel 2.3GHz, 2.1 - 2.16 avaialble
#shape="VM.Standard.E2.1" # AMD 2.0GHz, 2.1 - 2.8 avalable (slow)
pub_key="/home/ted/OCI/id_rsa.pub"
priv_key="/home/ted/OCI/id_rsa"
#image_id="ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaj5gzerswfvzsv4wrwngejgujbyiu7kzgclzhftsx6w4grjxfad4q"
image_id="ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaqgwqmwsddnbjzbbfaxs36jd36puvxpme76xvt3kpbfnpkhbwdobq"
      # My latest MySQL8NodeTemplate202004....
nw_id="ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaanpn7kqifmlmfddxpierfaynuqsj5hnwaradpt3o3g6rgnyzp3fua"
      # OpenNW, subnet of NWwDNS

prefix=$1
no_nodes=$2
[ $# -ne 2 ] && echo "Wrong number of arguments, Usage: $0 <prefix for nodes> <no of nodes>" && exit
[ -z "$prefix" ] && echo "You must add a prefix string, Usage: $0 <prefix for nodes> <no of nodes>" && exit
[[ $no_nodes -lt 0 || $no_nodes -gt 20 ]] && echo "Number of Nodes can only be 1-20" && exit

i=1
while [ $i -le $no_nodes ]
do
   server="${prefix}Node${i}"
   echo "Launching server $server... "
   
   id=`oci compute instance launch \
   --availability-domain $ad \
   --compartment-id $comp_id \
   --shape $shape \
   --display-name $server \
   --hostname-label $server \
   --image-id $image_id \
   --ssh-authorized-keys-file $pub_key \
   --subnet-id $nw_id \
   --assign-public-ip true \
   --wait-for-state "RUNNING" | jq .data.id | tr -d '"'`
   id_list="$id $id_list"
   # echo $id_list
   i=`expr $i + 1`
done

mdkir -p /tmp/oci
echo $id_list > "/tmp/oci/${prefix}NodesStarted.ids"
rm -f "/tmp/oci/${prefix}Nodes.txt"

for id in $id_list
do
   # echo $id
   oci compute instance list-vnics --query data[0].['"display-name"','"public-ip"','"private-ip"'] --raw-output --instance-id $id >> "/tmp/oci/${prefix}Nodes.txt"
   ip=`oci compute instance list-vnics --query data[0].'"public-ip"' --raw-output --instance-id $id | tr -d '"'`
   echo $ip
   ip_list="$ip $ip_list"
   # echo $ip_list
done

# Need to wait for sshd to start ...
for ip in $ip_list
do
   #echo $ip
   state=$( ssh -q -o "ConnectTimeout=5" -o "StrictHostKeyChecking=no" -i $priv_key opc@$ip 'whoami' )
   #echo $state
   while [ "$state" != "opc" ]
   do
      echo "SSH Daemon not up (state=$state), sleep some more ...."
      state=$( ssh -q -o "ConnectTimeout=5" -o "StrictHostKeyChecking=no" -i $priv_key opc@$ip 'whoami' )
      sleep 3
   done
done

# Start MySQL Servers
echo "Starting MySQL Servers"
i=1000
for ip in $ip_list
do
   ssh -o "ConnectTimeout=10" -o "StrictHostKeyChecking=no" -f -i $priv_key opc@$ip "sed s/server-id=3310/server-id=$i/ /home/opc/my.cnf > /home/opc/my.cnf.tmp ; mv /home/opc/my.cnf.tmp /home/opc/my.cnf" >/dev/null 2>/dev/null
   ssh -o "ConnectTimeout=10" -o "StrictHostKeyChecking=no" -f -i $priv_key opc@$ip '/home/opc/refresh.sh' >/dev/null 2>/dev/null
   i=`expr $i + 1`
done

echo "All nodes up and running"
echo "look in file /tmp/oci/${prefix}Nodes.txt"
cat "/tmp/oci/${prefix}Nodes.txt"
exit 0

