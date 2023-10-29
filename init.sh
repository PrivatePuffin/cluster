#!/bin/bash

export VIP=10.0.40.0

# Generate Talos Secrets
talosctl gen secrets -o talos.secret

# Uncomment to generate new node configurations
talosctl gen config "main" "https://$VIP:6443" --config-patch-control-plane @patches/init/controlplane.json --config-patch-worker @patches/init/worker.json -o config --with-secrets talos.secret --force


./update.sh

# ./apply.sh
# 
# talosctl --talosconfig=./talosconfig config endpoint 10.0.40.16 10.0.40.17 10.0.40.18
# talosctl config merge ./talosconfig
# 
# sleep 240
# 
# # It will take a few minutes for the nodes to spin up with the configuration.  Once ready, execute
# talosctl bootstrap -n 10.0.40.16
# 
# sleep 240
# 
# # It will then take a few more minutes for Kubernetes to get up and running on the nodes. Once ready, execute
# talosctl kubeconfig -n 10.0.40.16