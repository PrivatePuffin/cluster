export SOPS_AGE_KEY_FILE="age.key"
sops -d -i talos.secret
sops -d -i patches/custom/controlplane.json patches/custom/worker.json
find ./config -type f -exec sops -d -i {} \;
