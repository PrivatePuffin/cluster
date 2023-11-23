#!/bin/bash

approve_certs(){
kubectl certificate approve $(kubectl get csr --sort-by=.metadata.creationTimestamp | grep Pending | awk '{print $1}') 2>/dev/null
sleep 10
kubectl certificate approve $(kubectl get csr --sort-by=.metadata.creationTimestamp | grep Pending | awk '{print $1}') 2>/dev/null
sleep 10
kubectl certificate approve $(kubectl get csr --sort-by=.metadata.creationTimestamp | grep Pending | awk '{print $1}') 2>/dev/null
sleep 10
kubectl certificate approve $(kubectl get csr --sort-by=.metadata.creationTimestamp | grep Pending | awk '{print $1}') 2>/dev/null
}
export approve_certs
