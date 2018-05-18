list_gfs_ip_address=( $(echo $1|tr "," "\n") )
template_password=$2
template_username=root
echo "if root user password is not changeme, topology_modification.sh will fail to add manage hostname to topology.json"
#sudo su
cp /root/topology.json.sample /root/topology.json
i=0
for ip in ${list_gfs_ip_address[@]}
do
        hostName=$(sshpass -p ${template_password} ssh -o StrictHostKeyChecking=no ${template_username}@${ip} sudo hostname)
        jq ".clusters[0].nodes[$i].node.hostnames.manage = ([\"${hostName}\"])" < /root/topology.json > /root/topology1.json
        mv /root/topology1.json /root/topology.json
        jq ".clusters[0].nodes[$i].node.hostnames.storage = ([\"${ip}\"])" < /root/topology.json > /root/topology1.json
        mv /root/topology1.json /root/topology.json
        jq ".clusters[0].nodes[$i].node.zone = 1" < /root/topology.json > /root/topology1.json
        mv /root/topology1.json /root/topology.json
        jq ".clusters[0].nodes[$i].devices = ([\"\/dev\/xvda\"])" < /root/topology.json > /root/topology1.json
        mv /root/topology1.json /root/topology.json
        i=$(($i+1))
        #IPHOSTNAMEMAP[$ip]=$hostName
done