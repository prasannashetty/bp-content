

rm -rf /var/lib/kubelet/*
echo "rm -rf /var/lib/kubelet/*" > /tmp/join_node.sh
kubeadm init --pod-network-cidr=10.244.0.0/16 > /tmp/tmp_join_node.sh
cat "/tmp/tmp_join_node.sh" | grep "kubeadm join" >> /tmp/join_node.sh
rm -rf "/tmp/tmp_join_node.sh"

rm -rf $HOME/.kube
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
sudo iptables -P FORWARD ACCEPT

#Installing a pod network (Fannel)

sysctl net.bridge.bridge-nf-call-iptables=1
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
kubectl create clusterrolebinding permissive-binding \
  --clusterrole=cluster-admin \
  --user=admin \
  --user=kubelet \
  --group=system:serviceaccounts

kubectl get pods --namespace=kube-system


