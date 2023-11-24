#!/bin/bash

deploy_cni(){
if test -d ./deps/cni/charts; then
  rm -rf ./deps/cni/charts
fi
cat ./cluster/kube-system/cilium/cilium-values.yaml > ./deps/cni/values.yaml
kustomize build --enable-helm ./deps/cni | kubectl apply -f -
rm ./deps/cni/values.yaml
if test -d ./deps/csr-approver/charts; then
  rm -rf ./deps/csr-approver/charts
fi
}
export deploy_cni

deploy_approver(){
if test -d ./deps/csr-approver/charts; then
  rm -rf ./deps/csr-approver/charts
fi
cat ./cluster/kube-system/kubelet-csr-approver/values.yaml > ./deps/csr-approver/values.yaml
kustomize build --enable-helm ./deps/csr-approver | kubectl apply -f -
rm ./deps/csr-approver/values.yaml
if test -d ./deps/csr-approver/charts; then
  rm -rf ./deps/csr-approver/charts
fi
popd >/dev/null 2>&1
}
export deploy_approver
