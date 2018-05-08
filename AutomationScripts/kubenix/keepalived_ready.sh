kacp=0
while(($kacp<=0))
	do
		OUTPUT=$(kubectl get po --all-namespaces | grep -i keepalived-cloud-provider | grep -i "Running" | wc -l)
		kacp=$OUTPUT
		sleep 30
	done