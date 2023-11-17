#!/bin/bash

source settings.sh

prompt_yn_node () {
read -p "Is the currently updated node working correctly? please verify! (yes/no) " yn

case $yn in
    yes ) echo ok, we will proceed;;
    no ) echo exiting...;
        exit;;
    * ) echo invalid response;
        prompt_yn;;
esac
}

upgrade_talos_nodes () {
  echo "updating Talos on Node Master-A1"
  talosctl upgrade --nodes $MASTERA1 \
      --image ghcr.io/siderolabs/installer:v1.5.4 --preserve=true --stage
  prompt_yn_node
  echo "updating Talos on Node Master-B1"
  talosctl upgrade --nodes $MASTERB1 \
      --image ghcr.io/siderolabs/installer:v1.5.4 --preserve=true --stage
  prompt_yn_node
  echo "updating Talos on Node Master-C1"
  talosctl upgrade --nodes $MASTERC1 \
      --image ghcr.io/siderolabs/installer:v1.5.4 --preserve=true --stage
  prompt_yn_node
  echo "executing mandatory 1 minute wait..."
  sleep 60
  echo "updating kubernetes to latest version..."
  talosctl upgrade-k8s
}

encrypted_files () {
  local -n FILES=$1             # use nameref for indirection
  local FILES=('patches/custom/controlplane.json' 'patches/custom/worker.json' 'config/talosconfig')
  while IFS=  read -r -d $'\0'; do
      FILES+=("$REPLY")
  done < <(find . -name "*.yaml" -type f -print0)

  while IFS=  read -r -d $'\0'; do
      FILES+=("$REPLY")
  done < <(find . -name "*.secret" -type f -print0)
  return FILES
}

decrypt () {
  export SOPS_AGE_KEY_FILE="age.agekey"

  local FILES
  encrypted_files FILES

  if test -f "ENCRYPTED"; then
    for value in "${FILES[@]}"
    do
      echo "$value"
      sops -d -i "$value" || echo "skipping..."
    done
    rm -f ENCRYPTED
  else
    echo "ERROR DATA ALREADY DECRYPTED"
  fi
}

encrypt () {
  export SOPS_AGE_KEY_FILE="age.agekey"

  local FILES
  encrypted_files FILES

  if test -f "ENCRYPTED"; then
    echo "ERROR DATA ALREADY ENCRYPTED"
  else
    for value in "${FILES[@]}"
    do
      echo "$value"
      sops --encrypt -i "$value" || echo "skipping..."
    done
    touch ENCRYPTED
  fi
}



menu(){
    clear -x
    title
    echo -e "${bold}Available Utilities${reset}"
    echo -e "${bold}-------------------${reset}"
    echo -e "1)  Help"
    echo -e "2)  Decrypt Data"
    echo -e "3)  Encrypt Data"
    echo -e "4)  (re)Generate Cluster Config"
    echo -e "5)  Bootstrap Talos Cluster"
    echo -e "6)  Update Talos Cluster Config"
    echo -e "7)  Upgrade Talos Cluster Nodes"
    echo -e "8)  Bootstrap FluxCD Cluster"
    echo
    echo -e "0)  Exit"
    read -rt 120 -p "Please select an option by number: " selection || { echo -e "${red}\nFailed to make a selection in time${reset}" ; exit; }


    case $selection in
        0)
            echo -e "Exiting.."
            exit
            ;;
        1)
            main_help
            exit
            ;;

        2)
            decrypt
            exit
            ;;
        3)
            encrypt
            exit
            ;;
        4)
            regen
            exit
            ;;
        5)
            bootstrap_talos
            exit
            ;;
        6)
            update_talos_config
            exit
            ;;
        7)
            upgrade_talos_nodes
            exit
            ;;
        8)
            bootstrap_flux
            exit
            ;;

    esac
    echo
}
export -f menu

regen(){
# Prep precommit
pre-commit install --install-hooks

# Generate age key if not present
age-keygen -o age.agekey
AGE=$(cat age.agekey | grep public | sed -e "s|# public key: ||" )
cat templates/.sops.yaml.templ | sed -e "s|!!AGE!!|$AGE|"  > .sops.yaml

# Save an encrypted version of the age key, encrypted with itself
cat age.agekey | age -r age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p > age.agekey.enc

cat templates/agekey.yaml.templ | sed -e "s|!!AGEKEY!!|$( base64 age.agekey -w0 )|" > cluster/flux-system/agekey.yaml

# Generate Talos Secrets
talosctl gen secrets -o talos.secret

# Uncomment to generate new node configurations
talosctl gen config "main" "https://$VIP:6443" --config-patch-control-plane @patches/init/controlplane.json --config-patch-worker @patches/init/worker.json -o config --with-secrets talos.secret --force


echo "patching config..."

# Apply update patches
talosctl machineconfig patch config/controlplane.yaml --patch @patches/update/controlplane.json -o config/controlplane.yaml
talosctl machineconfig patch config/worker.yaml --patch @patches/update/worker.json -o config/worker.yaml

# Apply custom user patches
talosctl machineconfig patch config/controlplane.yaml --patch @patches/custom/controlplane.json -o config/controlplane.yaml
talosctl machineconfig patch config/worker.yaml --patch @patches/custom/worker.json -o config/worker.yaml

LOCATION="main"
# Control plane configuration
cat config/controlplane.yaml | sed -e "s|!!HOSTNAME!!|k8s-control-a1|" | sed -e "s|!!VIP!!|$VIP|" | sed -e "s|!!MASTERWORKLOADS!!|$MASTERWORKLOADS|" | sed -e "s|!!RACKID!!|rack-a|" | sed -e "s|!!MASTERA1!!|$MASTERA1|" > config/controlplane/k8s-control-a1.yaml
cat config/controlplane.yaml | sed -e "s|!!HOSTNAME!!|k8s-control-b1|" | sed -e "s|!!VIP!!|$VIP|" | sed -e "s|!!MASTERWORKLOADS!!|$MASTERWORKLOADS|" | sed -e "s|!!RACKID!!|rack-b|" | sed -e "s|!!MASTERB1!!|$MASTERB1|" > config/controlplane/k8s-control-b1.yaml
cat config/controlplane.yaml | sed -e "s|!!HOSTNAME!!|k8s-control-c1|" | sed -e "s|!!VIP!!|$VIP|" | sed -e "s|!!MASTERWORKLOADS!!|$MASTERWORKLOADS|" | sed -e "s|!!RACKID!!|rack-c|" | sed -e "s|!!MASTERC1!!|$MASTERC1|" > config/controlplane/k8s-control-c1.yaml

# Worker configuration
RACK="rack-a"
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-a1/" | sed -e "s|!!RACKID!!|$RACK|"  > config/workers/k8s-worker-a1.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-a2/" | sed -e "s|!!RACKID!!|$RACK|"  > config/workers/k8s-worker-a2.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-a3/" | sed -e "s|!!RACKID!!|$RACK|"  > config/workers/k8s-worker-a3.yaml
RACK="rack-b"
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-b1/" | sed -e "s|!!RACKID!!|$RACK|"  > config/workers/k8s-worker-b1.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-b2/" | sed -e "s|!!RACKID!!|$RACK|"  > config/workers/k8s-worker-b2.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-b3/" | sed -e "s|!!RACKID!!|$RACK|"  > config/workers/k8s-worker-b3.yaml
RACK="rack-c"
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-c1/" | sed -e "s|!!RACKID!!|$RACK|"  > config/workers/k8s-worker-c1.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-c2/" | sed -e "s|!!RACKID!!|$RACK|"  > config/workers/k8s-worker-c2.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-c3/" | sed -e "s|!!RACKID!!|$RACK|"  > config/workers/k8s-worker-c3.yaml
}
export -f regen

bootstrap_talos(){
  talosctl apply-config -i -n $MASTERA1 -f config/controlplane/k8s-control-a1.yaml
  talosctl apply-config -i -n $MASTERB1 -f config/controlplane/k8s-control-b1.yaml
  talosctl apply-config -i -n $MASTERC1 -f config/controlplane/k8s-control-c1.yaml

  talosctl --talosconfig=./talosconfig config endpoint $VIP $MASTERA1 $MASTERB1 $MASTERC1
  talosctl config merge ./talosconfig

  sleep 180

  # It will take a few minutes for the nodes to spin up with the configuration.  Once ready, execute
  talosctl bootstrap -n $MASTERA1

  sleep 180

  # It will then take a few more minutes for Kubernetes to get up and running on the nodes. Once ready, execute
  talosctl kubeconfig -n $VIP
}
export -f bootstrap_talos

bootstrap_flux(){
 flux check --pre
 flux bootstrap github \
   --token-auth=false \
   --owner=$GITHUB_USER \
   --repository=$GITHUB_REPOSITORY \
   --branch=main \
   --path=./clusters/main \
   --personal \
   --toleration-keys=node-role.kubernetes.io/control-plane
}
export -f bootstrap_flux

update_talos_config(){
  echo "CLUSTER ALREADY INITIATED, updating configuration..."
  echo "applying new operating system config to MASTER-A1..."
  talosctl apply-config -n $MASTERA1 -f config/controlplane/k8s-control-a1.yaml
  prompt_yn
  echo "applying new operating system config to MASTER-B1..."
  talosctl apply-config -n $MASTERB1 -f config/controlplane/k8s-control-b1.yaml
  prompt_yn
  echo "applying new operating system config to MASTER-C1..."
  talosctl apply-config -n $MASTERC1 -f config/controlplane/k8s-control-c1.yaml
  prompt_yn
}
export -f update_talos_config

menu
