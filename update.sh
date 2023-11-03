
echo "patching config..."

# Apply update patches
talosctl machineconfig patch config/controlplane.yaml --patch @patches/update/controlplane.json -o config/controlplane.yaml
talosctl machineconfig patch config/worker.yaml --patch @patches/update/worker.json -o config/worker.yaml

# Apply custom user patches
talosctl machineconfig patch config/controlplane.yaml --patch @patches/custom/controlplane.json -o config/controlplane.yaml
talosctl machineconfig patch config/worker.yaml --patch @patches/custom/worker.json -o config/worker.yaml

# Control plane configuration
cat config/controlplane.yaml | sed -e "s|!!HOSTNAME!!|k8s-control-1|" > config/controlplane/k8s-control-1.yaml
cat config/controlplane.yaml | sed -e "s|!!VIP!!|$VIP|" > config/controlplane/k8s-control-1.yaml

cat config/controlplane.yaml | sed -e "s|!!HOSTNAME!!|k8s-control-2|" > config/controlplane/k8s-control-2.yaml
cat config/controlplane.yaml | sed -e "s|!!VIP!!|$VIP|" > config/controlplane/k8s-control-2.yaml

cat config/controlplane.yaml | sed -e "s|!!HOSTNAME!!|k8s-control-3|" > config/controlplane/k8s-control-3.yaml
cat config/controlplane.yaml | sed -e "s|!!VIP!!|$VIP|" > config/controlplane/k8s-control-3.yaml

# Worker configuration
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-1/" > config/workers/k8s-worker-A-1.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-1/" > config/workers/k8s-worker-A-2.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-1/" > config/workers/k8s-worker-A-3.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-2/" > config/workers/k8s-worker-B-1.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-2/" > config/workers/k8s-worker-B-2.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-2/" > config/workers/k8s-worker-B-3.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-3/" > config/workers/k8s-worker-C-1.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-3/" > config/workers/k8s-worker-C-2.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-3/" > config/workers/k8s-worker-C-3.yaml
