#!/usr/bin/sudo bash

deploy_cni(){
rm -rf ./deps/cni/charts || true
rm -f ./deps/cni/values.yaml || true
cat ./cluster/kube-system/cilium/app/cilium-values.yaml > ./deps/cni/values.yaml
kustomize build --enable-helm ./deps/cni | kubectl apply -f -
rm -f ./deps/cni/values.yaml || true
rm -rf ./deps/csr-approver/charts || true
}
export deploy_cni

deploy_approver(){
rm -rf ./deps/csr-approver/charts || true
kustomize build --enable-helm ./deps/csr-approver | kubectl apply -f -
rm -rf ./deps/csr-approver/charts || true
popd >/dev/null 2>&1
}
export deploy_approver
