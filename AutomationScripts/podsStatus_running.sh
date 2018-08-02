beforeHelloWorld=$(kubectl get po --all-namespaces | wc -l)
beforeHelloWorld=$(($beforeHelloWorld-1))
afterHelloWorld=0
while(("$beforeHelloWorld" != "$afterHelloWorld"))
	do
		OUTPUT=$(kubectl get po --all-namespaces | grep -i "Running" | wc -l)
		afterHelloWorld=$OUTPUT
		sleep 30
		cnt=0
    	pods_not_running_state=( $(kubectl get pods -n kube-system -o template --template="{{range.items}}{{if ne .status.phase \"Running\"}}{{.metadata.name}} {{end}}{{end}}" | tr " " "\n" | grep -i "kube-keepalived-vip") )
	    for pod in ${pods_not_running_state[@]}
		    do
		        cnt=$(($cnt+1))
		        kubectl delete pod $pod -n kube-system
		    done
		if [ $cnt -ne 0 ]
	    then
	        sleep 30
	    fi
	    beforeHelloWorld=$(kubectl get po --all-namespaces | wc -l)
        beforeHelloWorld=$(($beforeHelloWorld-1))
        echo "\$beforeHelloWorld $beforeHelloWorld"
        echo "\$afterHelloWorld $afterHelloWorld"
        echo "if never matching, verify /root/keepalived-cloud-provider.yaml updated with cidr value"
	done
