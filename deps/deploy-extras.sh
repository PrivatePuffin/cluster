#!/usr/bin/sudo bash

deploy_cni(){
rm -rf ./deps/cni/charts || true
cat ./cluster/kube-system/cilium/app/cilium-values.yaml > ./deps/cni/values.yaml
kustomize build --enable-helm ./deps/cni | kubectl apply -f -
rm -f ./deps/cni/values.yaml || true
rm -rf ./deps/csr-approver/charts || true
}
export deploy_cni

deploy_approver(){
rm -rf ./deps/csr-approver/charts || true
cat ./cluster/kube-system/kubelet-csr-approver/app/values.yaml > ./deps/csr-approver/values.yaml
kustomize build --enable-helm ./deps/csr-approver | kubectl apply -f -

rm -f ./deps/csr-approver/values.yaml || true
rm -rf ./deps/csr-approver/charts || true
popd >/dev/null 2>&1
}
export deploy_approver
