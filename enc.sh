export SOPS_AGE_KEY_FILE="age.key"
sops --encrypt -i talos.secret
sops --encrypt -i patches/custom/controlplane.json patches/custom/worker.json
find ./config -type f -exec sops --encrypt -i {} \;
