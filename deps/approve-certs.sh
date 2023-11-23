#!/bin/bash

approve_certs(){
kubectl certificate approve $(kubectl get csr --sort-by=.metadata.creationTimestamp | grep Pending | awk '{print $1}')
}
export approve_certs
