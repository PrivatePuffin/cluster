#!/bin/bash

source settings.sh

export FILES


check_master () {
  echo "Checking presence of ControlePane nodes..."
  ping ${MASTER1} 2>&1 >/dev/null || (echo "Cannot ping controlnode 1" && exit 1)
  ping ${MASTER2} 2>&1 >/dev/null || (echo "Cannot ping controlnode 2" && exit 1)
  ping ${MASTER3} 2>&1 >/dev/null || (echo "Cannot ping controlnode 3" && exit 1)
  echo "All ControlPane nodes found..."
}
export -f check_master

prompt_yn_node () {
check_master
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
  check_master
  echo "updating Talos on Node Master-A1"
  talosctl upgrade --nodes $MASTER1 \
      --image ghcr.io/siderolabs/installer:v1.5.4 --preserve=true --stage
  prompt_yn_node
  echo "updating Talos on Node Master-B1"
  talosctl upgrade --nodes $MASTER2 \
      --image ghcr.io/siderolabs/installer:v1.5.4 --preserve=true --stage
  prompt_yn_node
  echo "updating Talos on Node Master-C1"
  talosctl upgrade --nodes $MASTER3 \
      --image ghcr.io/siderolabs/installer:v1.5.4 --preserve=true --stage
  prompt_yn_node
  echo "executing mandatory 1 minute wait..."
  sleep 60
  echo "updating kubernetes to latest version..."
  check_master
  talosctl upgrade-k8s
}

encrypted_files () {
  FILES=('patches/custom/controlplane.json' 'patches/custom/worker.json' 'config/talosconfig')
  while IFS=  read -r -d $'\0'; do
      FILES+=("$REPLY")
  done < <(find . -name "*.yaml" -type f -print0)

  while IFS=  read -r -d $'\0'; do
      FILES+=("$REPLY")
  done < <(find . -name "*.secret" -type f -print0)
}

decrypt () {
  export SOPS_AGE_KEY_FILE="age.agekey"

  encrypted_files

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

  encrypted_files

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

if [ "$SINGLENODE" = false ] ; then
MASTERWORKLOADS=true
fi
# Control plane configuration
cat config/controlplane.yaml | sed -e "s|!!HOSTNAME!!|k8s-control-1|" | sed -e "s|!!VIP!!|$VIP|" | sed -e "s|'!!MASTERWORKLOADS!!'|$MASTERWORKLOADS|" | sed -e "s|!!MASTER1!!|$MASTER1|" > config/controlplane/k8s-control-1.yaml
cat config/controlplane.yaml | sed -e "s|!!HOSTNAME!!|k8s-control-2|" | sed -e "s|!!VIP!!|$VIP|" | sed -e "s|'!!MASTERWORKLOADS!!'|$MASTERWORKLOADS|" | sed -e "s|!!MASTER2!!|$MASTER2|" > config/controlplane/k8s-control-2.yaml
cat config/controlplane.yaml | sed -e "s|!!HOSTNAME!!|k8s-control-3|" | sed -e "s|!!VIP!!|$VIP|" | sed -e "s|'!!MASTERWORKLOADS!!'|$MASTERWORKLOADS|" | sed -e "s|!!MASTER3!!|$MASTER3|" > config/controlplane/k8s-control-3.yaml

# Worker configuration
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-1/"  > config/workers/k8s-worker-1.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-2/"  > config/workers/k8s-worker-2.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-3/"  > config/workers/k8s-worker-3.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-4/"  > config/workers/k8s-worker-4.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-5/"  > config/workers/k8s-worker-5.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-6/"  > config/workers/k8s-worker-6.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-7/"  > config/workers/k8s-worker-7.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-8/"  > config/workers/k8s-worker-8.yaml
cat config/worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-worker-9/"  > config/workers/k8s-worker-9.yaml
}
export -f regen

bootstrap_talos(){
  check_master
  echo "Bootstrapping TalosOS Cluster..."
  echo "Applying TalosOS Cluster config to ${MASTER1}! ..."
  talosctl apply-config -i -n $MASTER1 -f config/controlplane/k8s-control-1.yaml
  if [ "$SINGLENODE" = false ] ; then
    echo "Applying TalosOS Cluster config to ${MASTER2}! ..."
    talosctl apply-config -i -n $MASTER2 -f config/controlplane/k8s-control-2.yaml
    echo "Applying TalosOS Cluster config to ${MASTER3}! ..."
    talosctl apply-config -i -n $MASTER3 -f config/controlplane/k8s-control-3.yaml
  fi

  echo "Updating talosconfig file..."

  if [ "$SINGLENODE" = false ] ; then
    ENDPOINT=$(echo "$VIP $MASTER1")
  else
    ENDPOINT=$(echo "$VIP $MASTER1 $MASTER2 $MASTER3")
  fi

  talosctl --talosconfig=./config/talosconfig config endpoint $ENDPOINT
  talosctl config merge ./config/talosconfig

  echo "Waiting for 3 minutes before bootstrapping..."
  sleep 180
  check_master

  # It will take a few minutes for the nodes to spin up with the configuration.  Once ready, execute
  talosctl bootstrap -n $MASTER1

  echo "Waiting for 3 minutes to finish bootstrapping..."
  sleep 180
  check_master

  # It will then take a few more minutes for Kubernetes to get up and running on the nodes. Once ready, execute
  talosctl kubeconfig -n $VIP
  echo "Bootstrapping finished..."
}
export -f bootstrap_talos

bootstrap_flux(){
 echo "Bootstrapping FluxCD on existing Cluster..."
 check_master
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
  check_master
  echo "Updating Talos Cluster Configuration..."
  echo "applying new operating system config to MASTER-A1..."
  talosctl apply-config -n $MASTER1 -f config/controlplane/k8s-control-1.yaml
  check_master
  prompt_yn
  if [ "$SINGLENODE" = false ] ; then
    echo "applying new operating system config to MASTER-B1..."
    talosctl apply-config -n $MASTER2 -f config/controlplane/k8s-control-2.yaml
    check_master
    prompt_yn
    echo "applying new operating system config to MASTER-C1..."
    talosctl apply-config -n $MASTER3 -f config/controlplane/k8s-control-.yaml
    check_master
    prompt_yn
  fi
}
export -f update_talos_config

menu
