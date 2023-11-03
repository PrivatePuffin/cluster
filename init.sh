#!/bin/bash

export VIP=10.0.40.0
export GITHUB_TOKEN="<your-token>"
export GITHUB_USER="<your-username>"
export GITHUB_REPOSITORY="<your-repository-name>"

# Generate age key if not present
age-keygen -o age.key

AGE=$(cat age.key | grep public | sed -e "s|# public key: ||" )

cat templates/.sops.yaml.templ | sed -e "s|!!AGE!!|$AGE|"  > .sops.yaml

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
#
# sleep 240
# flux check --pre
# flux bootstrap github \
#   --token-auth=false \
#   --owner=$GITHUB_USER \
#   --repository=$GITHUB_REPOSITORY \
#   --branch=main \
#   --path=./clusters/main \
#   --personal