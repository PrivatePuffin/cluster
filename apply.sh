# Cluster running using Proxmox VMs for control plane nodes
talosctl apply-config -i -n 10.0.40.16 -f config/controlplane/k8s-control-1.yaml
talosctl apply-config -i -n 10.0.40.17 -f config/controlplane/k8s-control-2.yaml
talosctl apply-config -i -n 10.0.40.18 -f config/controlplane/k8s-control-3.yaml

talosctl apply-config -i -n 10.0.40.19 -f config/workers/k8s-worker-1.yaml
talosctl apply-config -i -n 10.0.40.20 -f config/workers/k8s-worker-2.yaml
talosctl apply-config -i -n 10.0.40.21 -f config/workers/k8s-worker-3.yaml

