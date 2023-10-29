
echo "patching config..."

talosctl machineconfig patch config/controlplane.yaml --patch @patches/update/controlplane.json -o config/controlplane.yaml

talosctl machineconfig patch config/worker.yaml --patch @patches/update/worker.json -o config/worker.yaml

# Control plane configuration
cat config/controlplane.yaml | sed -e "s|!!HOSTNAME!!|k8s-control-1|" > config/controlplane/k8s-control-1.yaml
cat config/controlplane.yaml | sed -e "s|!!VIP!!|$VIP|" > config/controlplane/k8s-control-1.yaml

cat config/controlplane.yaml | sed -e "s|!!HOSTNAME!!|k8s-control-2|" > config/controlplane/k8s-control-2.yaml
cat config/controlplane.yaml | sed -e "s|!!VIP!!|$VIP|" > config/controlplane/k8s-control-2.yaml

cat config/controlplane.yaml | sed -e "s|!!HOSTNAME!!|k8s-control-3|" > config/controlplane/k8s-control-3.yaml
cat config/controlplane.yaml | sed -e "s|!!VIP!!|$VIP|" > config/controlplane/k8s-control-3.yaml

# Worker configuration
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-1/" > config/workers/k8s-worker-1.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-2/" > config/workers/k8s-worker-2.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-3/" > config/workers/k8s-worker-3.yaml
