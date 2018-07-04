#!/bin/sh
password=$1
sed -i 's/\[//g'  /root/node_addresses.txt
sed -i 's/\]//g' /root/node_addresses.txt
value=`cat /root/node_addresses.txt`
arr=$(echo $value | tr "," "\n")
count=1

for node in $arr
do
    echo "\"$node\""
    sshpass -p $password  scp  -o "StrictHostKeyChecking no" /tmp/join_node.sh root@$node:/tmp/
    sshpass -p $password  ssh  -o "StrictHostKeyChecking no" root@$node 'chmod 700 /tmp/join_node.sh'
    sshpass -p $password  ssh  -o "StrictHostKeyChecking no" root@$node '/tmp/join_node.sh'

    if [ $count = 1 ]
    then
    	sshpass -p $password  ssh  -o "StrictHostKeyChecking no" root@$node 'echo 1 >> /root/count.txt'
	    sshpass -p $password  ssh  -o "StrictHostKeyChecking no" root@$node 'count=$(</root/count.txt);echo "$(ifconfig $(route | grep '^default' | grep -o '[^ ]*$') | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1) node$count.kubernetes.cluster" >> /etc/hosts;echo $((count+1)) > /root/count.txt;sudo hostname node$count.kubernetes.cluster'
    else
    	sshpass -p $password  scp  -o "StrictHostKeyChecking no" root@$previous_node:/root/count.txt root@node:/root/count.txt
	    sshpass -p $password  ssh  -o "StrictHostKeyChecking no" root@$node 'count=$(</root/count.txt);echo "$(ifconfig $(route | grep '^default' | grep -o '[^ ]*$') | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1) node$count.kubernetes.cluster" >> /etc/hosts;echo $((count+1)) > /root/count.txt;sudo hostname node$count.kubernetes.cluster'
	fi
	previous_node = $node
done
