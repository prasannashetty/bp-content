#!/bin/bash

#sh deployment_kubenix.sh <IPs> <GlusterFSIPs> <ExternalIPs/CIDR>
#sh deployment_kubenix.sh "10.134.88.115-124" "10.134.88.125-126, 10.134.88.129" "10.196.173.64/29"

# Function to Trim the WhiteSpace by passing the variable
function trim(){
	#echo "In trim Function: ${1}"
	withSpace="${1}"
	withOutSpace="$(echo -e "${withSpace}" | tr -d '[:space:]')"
	echo "${withOutSpace}"
}

#Function to Split the variable by passing delimeter and variable as arguments, returns the array ($1=variable and $2=delimeter)
function split(){
	delimeter="$2"
	value="$1"
	IFS=',' read -a OUTARRAY <<< "${ip_address_range}"
	#echo "IFS='$2'"
        #read -a outputArray <<< $1
	#echo "read -a outputArray <<< $1"
	#echo $1
	#echo $2
	echo "${OUTARRAY}"
}

function getIPAddressList(){
	ip_address_value=$1
	ip_address_range=$(trim "${ip_address_value}")
	IFS=',' read -a ipAddressList <<< "${ip_address_range}"
	#ipAddressList=$(split "${ip_address_range}" ",")
	#echo "${ipAddressList}"
	final_ip_address_list=();
	for i in "${ipAddressList[@]}"
	do     
 		if [[ $i =~ "-" ]];
		then
			IFS='-' read -a splitIPAddress <<< "$i"
			final_ip_address_list=("${final_ip_address_list[@]}" "${splitIPAddress[0]}")
			prefix=$(echo "${splitIPAddress[0]}" | cut -d"." -f1-3)
			suffix=$(($(echo "${splitIPAddress[0]}" | cut -d"." -f4)+1))
			for (( c=$suffix; c<=${splitIPAddress[1]}; c++ ))
			do
				final_ip_address_list=("${final_ip_address_list[@]}" "${prefix}.${c}")
			done			
		else
			final_ip_address_list=("${final_ip_address_list[@]}" "${i}")
		fi
	done
	echo "${final_ip_address_list[@]}"
}


ip_address=$1
ip_address_gfs=$2
cidr=$3
template_password="kubernetes" #"B1gd3m0z"
template_username="root"
test_ip="10.134.215.229"
join_node_script_file="/tmp/join_node.sh"
join_node_script_path="/tmp/"

list_ip_address=$(getIPAddressList "${ip_address}")
list_gfs_ip_address=("$(getIPAddressList "${ip_address_gfs}")")
total_ip_address=("${list_ip_address[@]}" "${list_gfs_ip_address[@]}")

masterIP="$(echo "${list_ip_address[@]}" | cut -d" " -f1)"
total_ip_address_without_masterIP=( "${total_ip_address[@]/$masterIP/}" )

# To run PreRequisite Commands on All Nodes
for ip in ${total_ip_address[@]}
do
	cat /tmp/pre_requisite_commands.sh | sshpass -p ${template_password} ssh -o StrictHostKeyChecking=no ${template_username}@${ip} 'bash -'
done

# To run Command On Master Node
cat /tmp/master_node.sh | sshpass -p ${template_password} ssh -o StrictHostKeyChecking=no ${template_username}@${masterIP} 'bash -'
sshpass -p ${template_password} scp -o StrictHostKeyChecking=no ${template_userName}@${masterIP}:${join_node_script_file} ${join_node_script_path}${masterIP}.sh

#To Join Nodes to Master Node
for ip in ${total_ip_address_without_masterIP[@]}
do
	sshpass -p ${template_password} ssh -o StrictHostKeyChecking=no ${template_username}@${ip} kubeadm reset
	cat ${join_node_script_path}${masterIP}.sh | sshpass -p ${template_password} ssh -o StrictHostKeyChecking=no ${template_username}@${ip} 'bash -'
done

sleep 60
sshpass -p ${template_password} scp -o StrictHostKeyChecking=no /tmp/kubenix/podsStatus.sh ${template_username}@${masterIP}:/tmp/podsStatus.sh
sshpass -p ${template_password} ssh -o StrictHostKeyChecking=no ${template_username}@${masterIP} bash /tmp/podsStatus.sh

#Transfer vip-daemonset.yaml to /root/
sshpass -p ${template_password} scp -o StrictHostKeyChecking=no /tmp/kubenix/vip-daemonset.yaml ${template_username}@${masterIP}:/root/
sshpass -p ${template_password} ssh -o StrictHostKeyChecking=no ${template_username}@${masterIP} kubectl create -f /root/vip-daemonset.yaml

#Transfer kube-controller-manager.yaml to /etc/kubernetes/manifests/
sshpass -p ${template_password} scp -o StrictHostKeyChecking=no /tmp/kubenix/kube-controller-manager.yaml ${template_username}@${masterIP}:/etc/kubernetes/manifests/

#Transfer keepalived-cloud-provider.yaml to /root/ and Replace the CIDR Value with the user INput values
sshpass -p ${template_password} scp -o StrictHostKeyChecking=no /tmp/kubenix/keepalived-cloud-provider.yaml ${template_username}@${masterIP}:/root/

##CHeck jq exists in linux or not.. If not exists run the following commands
checkJq=$(which jq | wc -l)
if [ $checkJq -eq 0 ]
then
	wget http://stedolan.github.io/jq/download/linux64/jq
	chmod +x ./jq
	sudo cp jq /usr/bin
fi

#declare -A IPHOSTNAMEMAP
node_length=$(cat /tmp/kubenix/topology.json | jq '.clusters[0].nodes| length | head -1')

cp /tmp/kubenix/topology.json.sample /tmp/kubenix/topology.json
i=0
for ip in ${list_gfs_ip_address[@]}
do
	hostName=$(sshpass -p ${template_password} ssh -o StrictHostKeyChecking=no ${template_username}@${ip} hostname)
	jq ".clusters[0].nodes[$i].node.hostnames.manage = ([\"${hostName}\"])" < /tmp/kubenix/topology.json > /tmp/kubenix/topology1.json
	mv /tmp/kubenix/topology1.json /tmp/kubenix/topology.json
	jq ".clusters[0].nodes[$i].node.hostnames.storage = ([\"${ip}\"])" < /tmp/kubenix/topology.json > /tmp/kubenix/topology1.json
	mv /tmp/kubenix/topology1.json /tmp/kubenix/topology.json
	jq ".clusters[0].nodes[$i].node.zone = 1" < /tmp/kubenix/topology.json > /tmp/kubenix/topology1.json
	mv /tmp/kubenix/topology1.json /tmp/kubenix/topology.json
	jq ".clusters[0].nodes[$i].devices = ([\"\/dev\/sdb\"])" < /tmp/kubenix/topology.json > /tmp/kubenix/topology1.json
	mv /tmp/kubenix/topology1.json /tmp/kubenix/topology.json
	i=$(($i+1))
	#IPHOSTNAMEMAP[$ip]=$hostName
done

sshpass -p ${template_password} ssh -o StrictHostKeyChecking=no ${template_username}@${masterIP} "cd /etc/kubernetes;git clone https://github.com/gluster/gluster-kubernetes.git"

#Transfer topology.json file to /etc/kubernetes/gluster-kubernetes/deploy
sshpass -p ${template_password} scp -o StrictHostKeyChecking=no /tmp/kubenix/topology.json ${template_username}@${masterIP}:/etc/kubernetes/gluster-kubernetes/deploy

#Transfer deploy-heketi-deployment.yaml file to /etc/kubernetes/gluster-kubernetes/deploy/kube-templates
sshpass -p ${template_password} scp -o StrictHostKeyChecking=no /tmp/kubenix/deploy-heketi-deployment.yaml ${template_username}@${masterIP}:/etc/kubernetes/gluster-kubernetes/deploy/kube-templates

#Transfer heketi-deployment.yaml file to /etc/kubernetes/gluster-kubernetes/deploy/kube-templates
sshpass -p ${template_password} scp -o StrictHostKeyChecking=no /tmp/kubenix/heketi-deployment.yaml ${template_username}@${masterIP}:/etc/kubernetes/gluster-kubernetes/deploy/kube-templates

#Transfer glusterfs-daemonset.yaml file to /etc/kubernetes/gluster-kubernetes/deploy/kube-templates
sshpass -p ${template_password} scp -o StrictHostKeyChecking=no /tmp/kubenix/glusterfs-daemonset.yaml ${template_username}@${masterIP}:/etc/kubernetes/gluster-kubernetes/deploy/kube-templates

#Transfer Deployment.sh file to /tmp/
sshpass -p ${template_password} scp -o StrictHostKeyChecking=no /tmp/kubenix/deployment.sh ${template_username}@${masterIP}:/tmp/deployment.sh

sshpass -p ${template_password} ssh -o StrictHostKeyChecking=no ${template_username}@${masterIP} bash /tmp/deployment.sh $cidr