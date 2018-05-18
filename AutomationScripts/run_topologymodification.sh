#!/bin/sh
password=$1
sed -i 's/\[//g'  /root/node_addresses.txt
sed -i 's/\]//g' /root/node_addresses.txt
glusterfs_ips=`cat /root/node_addresses.txt`

/root/topology_modification.sh $glusterfs_ips $password >> /root/k8sinstallation_status.log