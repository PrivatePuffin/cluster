
echo "patching config..."

# Apply update patches
talosctl machineconfig patch config/controlplane.yaml --patch @patches/update/controlplane.json -o config/controlplane.yaml
talosctl machineconfig patch config/worker.yaml --patch @patches/update/worker.json -o config/worker.yaml

# Apply custom user patches
talosctl machineconfig patch config/controlplane.yaml --patch @patches/custom/controlplane.json -o config/controlplane.yaml
talosctl machineconfig patch config/worker.yaml --patch @patches/custom/worker.json -o config/worker.yaml

LOCATION="main"
# Control plane configuration
cat config/controlplane.yaml | sed -e "s|!!HOSTNAME!!|k8s-control-1|" | sed -e "s|!!VIP!!|$VIP|" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|rack-a|" > config/controlplane/k8s-control-a1.yaml
cat config/controlplane.yaml | sed -e "s|!!HOSTNAME!!|k8s-control-2|" | sed -e "s|!!VIP!!|$VIP|" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|rack-b|" > config/controlplane/k8s-control-b1.yaml
cat config/controlplane.yaml | sed -e "s|!!HOSTNAME!!|k8s-control-3|" | sed -e "s|!!VIP!!|$VIP|" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|rack-c|" > config/controlplane/k8s-control-c1.yaml

# Worker configuration
RACK="rack-a"
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-a1/" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|$RACK|"  > config/workers/k8s-worker-a1.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-a2/" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|$RACK|"  > config/workers/k8s-worker-a2.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-a3/" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|$RACK|"  > config/workers/k8s-worker-a3.yaml
RACK="rack-b"
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-b1/" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|$RACK|"  > config/workers/k8s-worker-b1.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-b2/" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|$RACK|"  > config/workers/k8s-worker-b2.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-b3/" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|$RACK|"  > config/workers/k8s-worker-b3.yaml
RACK="rack-c"
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-c1/" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|$RACK|"  > config/workers/k8s-worker-c1.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-c2/" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|$RACK|"  > config/workers/k8s-worker-c2.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-c3/" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|$RACK|"  > config/workers/k8s-worker-c3.yaml

# edge worker configuration
LOCATION="edge"
RACK="rack-d"
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-edge-a1/" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|$RACK|"  > config/edge-workers/k8s-edge-workers-a1.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-edge-a2/" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|$RACK|"  > config/edge-workers/k8s-edge-workers-a2.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-edge-a3/" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|$RACK|"  > config/edge-workers/k8s-edge-workers-a3.yaml
RACK="rack-e"
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-edge-b1/" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|$RACK|"  > config/edge-workers/k8s-edge-workers-b1.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-edge-b2/" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|$RACK|"  > config/edge-workers/k8s-edge-workers-b2.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-edge-b3/" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|$RACK|"  > config/edge-workers/k8s-edge-workers-b3.yaml
RACK="rack-f"
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-edge-c1/" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|$RACK|"  > config/edge-workers/k8s-edge-workers-c1.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-edge-c2/" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|$RACK|"  > config/edge-workers/k8s-edge-workers-c2.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-edge-c3/" | sed -e "s|!!LOCATION!!|$LOCATION|" | sed -e "s|!!RACKID!!|$RACK|"  > config/edge-workers/k8s-edge-workers-c3.yaml