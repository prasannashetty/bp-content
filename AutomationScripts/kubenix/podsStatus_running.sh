beforeHelloWorld=$(kubectl get po --all-namespaces | wc -l)
beforeHelloWorld=$(($beforeHelloWorld-1))
afterHelloWorld=0
while(("$beforeHelloWorld" != "$afterHelloWorld"))
	do
		OUTPUT=$(kubectl get po --all-namespaces | grep -i "Running" | wc -l)
		afterHelloWorld=$OUTPUT
		sleep 30
	done