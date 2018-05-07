#!/bin/bash

beforeJoin=$(kubectl get po --all-namespaces | wc -l)
beforeJoin=$(($beforeJoin-1))
afterJoin=0
while(("$beforeJoin" != "$afterJoin"))
do
	OUTPUT=$(kubectl get po --all-namespaces | grep -i "Running" | wc -l)
	afterJoin=$OUTPUT
	sleep 30
done