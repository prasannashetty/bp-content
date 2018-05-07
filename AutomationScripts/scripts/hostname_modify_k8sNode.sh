#!/bin/bash
#sh /root/hostname_modify_k8sNode.sh fi-88-118 K8SNode.eng.vmware.com K8SNode sqa.local
#sh /root/hostname_modify_k8sNode.sh fi-88-118 K8SNodeGFS.eng.vmware.com K8SNodeGFS sqa.local
#$1 = NewHostName
#$2 = previousTemplateHostName DomainName for 127.0.1.1 in Kube8SNode or Kube8SNodeGFS
#$3 = previousTemplateNodeName
#$4 = Domain like sqa.local or eng.vmware.com

echo $1
echo $2
echo $3
echo $4

#Assign existing hostname to $hostn
hostn=$(cat /etc/hostname)

#Display existing hostname
echo "Existing hostname is $hostn"

#Ask for new hostname $newhost
echo " New hostname is $1 "
#read newhost

#change hostname in /etc/hosts & /etc/hostname
sudo sed -i "s/$hostn/$1.$4/g" /etc/hosts
sudo sed -i "s/$hostn/$1.$4/g" /etc/hostname

#change previousTemplateHostName in /etc/hosts
pTNewHostName=$1.$4
sudo sed -i "s/$2/$pTNewHostName/g" /etc/hosts

#Change previousTemplateNodeName in /etc/hosts
sudo sed -i "s/$3/$1.$4/g" /etc/hosts

sudo sed -i "s/$4.$4/$4/g" /etc/hosts
#display new hostname
echo "Your new hostname is $pTNewHostName"

#Press a key to reboot
#read -s -n 1 -p "Press any key to continue"
sudo reboot
