# Cluster running using Proxmox VMs for control plane nodes
talosctl apply-config -i -n 10.0.40.16 -f config/controlplane/k8s-control-1.yaml
talosctl apply-config -i -n 10.0.40.17 -f config/controlplane/k8s-control-2.yaml
talosctl apply-config -i -n 10.0.40.18 -f config/controlplane/k8s-control-3.yaml

talosctl apply-config -i -n 10.0.40.19 -f config/workers/k8s-worker-1.yaml
talosctl apply-config -i -n 10.0.40.20 -f config/workers/k8s-worker-2.yaml
talosctl apply-config -i -n 10.0.40.21 -f config/workers/k8s-worker-3.yaml

talosctl --talosconfig=./talosconfig config endpoint 10.0.40.16 10.0.40.17 10.0.40.18
talosctl config merge ./talosconfig

sleep 240

# It will take a few minutes for the nodes to spin up with the configuration.  Once ready, execute
talosctl bootstrap -n 10.0.40.16

sleep 240

# It will then take a few more minutes for Kubernetes to get up and running on the nodes. Once ready, execute
talosctl kubeconfig -n 10.0.40.16