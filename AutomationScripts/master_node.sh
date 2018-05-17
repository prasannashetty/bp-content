

rm -rf /var/lib/kubelet/*
echo "rm -rf /var/lib/kubelet/*" > /tmp/join_node.sh
kubeadm init --pod-network-cidr=10.244.0.0/16 > /tmp/tmp_join_node.sh
echo "executed kubeadm command"
cat "/tmp/tmp_join_node.sh" | grep "kubeadm join" >> /tmp/join_node.sh
echo "executed /tmp/tmp_join_node.sh"
rm -rf "/tmp/tmp_join_node.sh"
echo "executed rm -rf tmp_join_node.sh"
rm -rf $HOME/.kube
echo "executing rm .kube"
mkdir -p $HOME/.kube
echo "executing mkdir .kube"
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
echo "executing cp admin.conf"
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo "executing iptables"
sudo iptables -P FORWARD ACCEPT

#Installing a pod network (Fannel)

sysctl net.bridge.bridge-nf-call-iptables=1
echo "executing sysctl"
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
echo "executing kubectl apply"
kubectl create clusterrolebinding permissive-binding \
  --clusterrole=cluster-admin \
  --user=admin \
  --user=kubelet \
  --group=system:serviceaccounts
echo "executing kubectl create"
kubectl get pods --namespace=kube-system
echo "executing kubectl get pods"


