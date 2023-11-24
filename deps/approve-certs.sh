#!/bin/bash

approve_certs(){
finished=false
echo "Waiting to approve certificates..."
while ! $finished; do
    kubectl certificate approve $(kubectl get csr --sort-by=.metadata.creationTimestamp | grep Pending | awk '{print $1}') && finished=true
done
}
export approve_certs
