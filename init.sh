#!/bin/bash

VIP=10.0.40.0
controlIP1=10.0.40.1/24
controlIP2=10.0.40.2/24
controlIP3=10.0.40.3/24

# Generate Talos Secrets
talosctl gen secrets -o talos.secret

# Uncomment to generate new node configurations
talosctl gen config "main" "https://$VIP:6443" --config-patch-control-plane @patches/init/controlplane.json --config-patch-worker @patches/init/worker.json -o config --with-secrets talos.secret --force

talosctl machineconfig patch config/controlplane.yaml --patch @patches/update/controlplane.json -o config/controlplane.yaml

talosctl machineconfig patch config/worker.yaml --patch @patches/update/worker.json -o config/worker.yaml

# Control plane configuration
cat config/controlplane.yaml | sed -e "s|!!HOSTNAME!!|k8s-control-1|" > config/controlplane/k8s-control-1.yaml
cat config/controlplane.yaml | sed -e "s|!!VIP!!|$VIP|" > config/controlplane/k8s-control-1.yaml
cat config/controlplane.yaml | sed -e "s|!!IP!!|$controlIP1|" > config/controlplane/k8s-control-1.yaml

cat config/controlplane.yaml | sed -e "s|!!HOSTNAME!!|k8s-control-2|" > config/controlplane/k8s-control-2.yaml
cat config/controlplane.yaml | sed -e "s|!!VIP!!|$VIP|" > config/controlplane/k8s-control-2.yaml
cat config/controlplane.yaml | sed -e "s|!!IP!!|$controlIP2|" > config/controlplane/k8s-control-2.yaml

cat config/controlplane.yaml | sed -e "s|!!HOSTNAME!!|k8s-control-3|" > config/controlplane/k8s-control-3.yaml
cat config/controlplane.yaml | sed -e "s|!!VIP!!|$VIP|" > config/controlplane/k8s-control-3.yaml
cat config/controlplane.yaml | sed -e "s|!!IP!!|$controlIP3|" > config/controlplane/k8s-control-3.yaml

# Worker configuration
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-1/" > config/workers/k8s-worker-1.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-2/" > config/workers/k8s-worker-2.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-3/" > config/workers/k8s-worker-3.yaml

