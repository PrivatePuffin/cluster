#!/bin/bash

export VIP=10.0.40.0

# Generate Talos Secrets
talosctl gen secrets -o talos.secret

# Uncomment to generate new node configurations
talosctl gen config "main" "https://$VIP:6443" --config-patch-control-plane @patches/init/controlplane.json --config-patch-worker @patches/init/worker.json -o config --with-secrets talos.secret --force


./update.sh