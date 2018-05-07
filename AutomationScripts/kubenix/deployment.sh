#!/bin/bash

#bash /tmp/kubenix/deployment.sh <CIDRAddress>

cidr=$1
echo $1
ip="10.134.88.224/29"
echo $cidr

sed -i "s|$ip|$cidr|g" /root/keepalived-cloud-provider.yaml
kubectl create -f /root/keepalived-cloud-provider.yaml

#This code waits till keepalived-cloud-provider is up

kacp=0
while(($kacp<=0))
do
	OUTPUT=$(kubectl get po --all-namespaces | grep -i keepalived-cloud-provider | grep -i "Running" | wc -l)
	kacp=$OUTPUT
	sleep 30
done

#The following commands run the hello-world sample service
kubectl run hello-world-2 --replicas=2 --labels="run=load-balancer-example-2" --image=gcr.io/google-samples/node-hello:1.0  --port=8080
kubectl get pods --all-namespaces
kubectl get replicasets --selector="run=load-balancer-example-2"
kubectl expose rs hello-world-2-75474bc577 --type="LoadBalancer" --name="hello-world-svc"

#This code waits till all pods status become as running

beforeHelloWorld=$(kubectl get po --all-namespaces | wc -l)
beforeHelloWorld=$(($beforeHelloWorld-1))
afterHelloWorld=0
while(("$beforeHelloWorld" != "$afterHelloWorld"))
do
	OUTPUT=$(kubectl get po --all-namespaces | grep -i "Running" | wc -l)
	afterHelloWorld=$OUTPUT
	sleep 30
done

#The following commands run the glusterfs deployment

cd /etc/kubernetes/gluster-kubernetes/deploy/
./gk-deploy -g
