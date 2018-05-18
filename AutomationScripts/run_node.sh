#!/bin/sh
password=$1
sed -i 's/\[//g'  /root/node_addresses.txt
sed -i 's/\]//g' /root/node_addresses.txt
value=`cat /root/node_addresses.txt`
arr=$(echo $value | tr "," "\n")

for node in $arr
do
    echo "\"$node\""
    sshpass -p $password  scp  -o "StrictHostKeyChecking no" /tmp/join_node.sh root@$node:/tmp/
    sshpass -p $password  ssh  -o "StrictHostKeyChecking no" root@$node 'chmod 700 /tmp/join_node.sh'
    sshpass -p $password  ssh  -o "StrictHostKeyChecking no" root@$node '/tmp/join_node.sh'
done
