#!/bin/bash

deploy_cni(){
if test -d cni/charts; then
  rm -rf cni/charts
fi
envsubst < ../cluster/system/kube-system/cilium/cilium-values.yaml > cni/values.yaml
kustomize build --enable-helm cni | kubectl apply -f -
rm cni/values.yaml
}
export deploy_cni

deploy_approver(){
if test -d csr-approver/charts; then
  rm -rf csr-approver/charts
fi
envsubst < ../cluster/system/kube-system/kubelet-csr-approver/values.yaml > csr-approver/values.yaml
kustomize build --enable-helm csr-approver | kubectl apply -f -
rm csr-approver/values.yaml
popd >/dev/null 2>&1
}
export deploy_approver
