#!/bin/bash

beforeJoin=$(kubectl get po --all-namespaces | wc -l)
beforeJoin=$(($beforeJoin-1))
afterJoin=0
echo "While loop started"
while(("$beforeJoin" != "$afterJoin"))
do
	OUTPUT=$(kubectl get po --all-namespaces | grep -i "Running" | wc -l)
	afterJoin=$OUTPUT
	echo "\$beforeJoin  $beforeJoin"  
	echo "\$afterJoin $afterJoin"
	echo "\$OUTPUT $OUTPUT"
	sleep 30
	beforeJoin=$(kubectl get po --all-namespaces | wc -l)
    beforeJoin=$(($beforeJoin-1))
done
echo "While loop Ended"
