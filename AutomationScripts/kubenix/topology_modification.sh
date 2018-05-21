list_gfs_ip_address=( $(echo $1|tr "," "\n") )

template_password=$2
template_username=root

disk_type=$3
path_var1=$(echo $disk_type | cut -f2 -d/)
path_var2=$(echo $disk_type | cut -f3 -d/)

cp /root/topology.json.sample /root/topology.json
i=0
for ip in ${list_gfs_ip_address[@]}
do
        echo "loop $i" 
        hostName=$(sshpass -p ${template_password} ssh -o StrictHostKeyChecking=no ${template_username}@${ip} sudo hostname)
        echo $hostName
        jq ".clusters[0].nodes[$i].node.hostnames.manage = ([\"${hostName}\"])" < /root/topology.json > /root/topology1.json
        mv /root/topology1.json /root/topology.json
        jq ".clusters[0].nodes[$i].node.hostnames.storage = ([\"${ip}\"])" < /root/topology.json > /root/topology1.json
        mv /root/topology1.json /root/topology.json
        jq ".clusters[0].nodes[$i].node.zone = 1" < /root/topology.json > /root/topology1.json
        mv /root/topology1.json /root/topology.json
        jq ".clusters[0].nodes[$i].devices = ([\"/$path_var1/$path_var2\"])" < /root/topology.json > /root/topology1.json
        mv /root/topology1.json /root/topology.json
        i=$(($i+1))
done