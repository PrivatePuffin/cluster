#!/bin/bash

source settings.sh

export FILES

function parse_yaml_env {
  echo "Processing $1..."
  if test -f "$1"; then
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3)
         ;
      }
   }' >> talenv.env
   set -o allexport; source talenv.env; set +o allexport
   rm -rf talenv.env
  fi

}
export parse_yaml_env

function parse_yaml_env_all {
    decrypt
    echo "Loading environment variables..."
    touch talenv.yaml
    parse_yaml_env talenv.sops.yaml
    parse_yaml_env talenv.yaml
    parse_yaml_env talenv.sops.yml
    parse_yaml_env talenv.yml
    echo "Done loading environment variables..."
}
export parse_yaml_env_all

check_master () {
  echo "Checking presence of ControlePane nodes..."
  ping ${MASTER1IP} 2>&1 >/dev/null || (echo "Cannot ping controlnode 1" && exit 1)
  ping ${MASTER2IP} 2>&1 >/dev/null || (echo "Cannot ping controlnode 2" && exit 1)
  ping ${MASTER3IP} 2>&1 >/dev/null || (echo "Cannot ping controlnode 3" && exit 1)
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
  talhelper gencommand --upgrade -n k8s-control-1 --extra-flags=--preserve=true --stage | bash
  prompt_yn_node
  echo "updating Talos on Node Master-B1"
  talhelper gencommand --upgrade -n k8s-control-2 --extra-flags=--preserve=true --stage | bash
  prompt_yn_node
  echo "updating Talos on Node Master-C1"
  talhelper gencommand --upgrade -n k8s-control-3 --extra-flags=--preserve=true --stage | bash
  prompt_yn_node
  echo "executing mandatory 1 minute wait..."
  sleep 60
  check_master
  echo "updating kubernetes to latest version..."
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
  echo "Trying to decrypt data..."
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
    echo "Data already decrypted..."
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
    echo -e "2)  Install/Update Dependencies"
    echo -e "3)  Decrypt Data"
    echo -e "4)  Encrypt Data"
    echo -e "5)  (re)Generate Cluster Config"
    echo -e "6)  Bootstrap Talos Cluster"
    echo -e "7)  Update Talos Cluster Config"
    echo -e "8)  Upgrade Talos Cluster Nodes"
    echo -e "9)  Bootstrap FluxCD Cluster"
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
            install_deps
            exit
            ;;
        3)
            decrypt
            exit
            ;;
        4)
            encrypt
            exit
            ;;
        5)
            regen
            exit
            ;;
        6)
            parse_yaml_env_all
            bootstrap_talos
            exit
            ;;
        7)
            parse_yaml_env_all
            update_talos_config
            exit
            ;;
        8)
            parse_yaml_env_all
            upgrade_talos_nodes
            exit
            ;;
        9)
            parse_yaml_env_all
            bootstrap_flux
            exit
            ;;
        t)
            parse_yaml_env_all
            exit
            ;;

    esac
    echo
}
export -f menu

regen(){
# Prep precommit
echo "Installing/Updating Pre-commit hook..."
pre-commit install --install-hooks


# Generate age key if not present
if test -f "talsecret.yaml"; then
  echo "Generating Age Encryption Key..."
  age-keygen -o age.agekey
  AGE=$(cat age.agekey | grep public | sed -e "s|# public key: ||" )
  cat templates/.sops.yaml.templ | sed -e "s|!!AGE!!|$AGE|"  > .sops.yaml

  # Save an encrypted version of the age key, encrypted with itself
  cat age.agekey | age -r age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p > age.agekey.enc

  cat templates/agekey.yaml.templ | sed -e "s|!!AGEKEY!!|$( base64 age.agekey -w0 )|" > cluster/flux-system/agekey.yaml

else
  echo "Age Encryption Key already exists, skipping..."
fi



if test -f "talsecret.yaml"; then
  echo "Generating Talos Secret"
  talhelper gensecret >>  talsecret.yaml
else
  echo "Talos Secret already exists, skipping..."
fi

echo "(re)generating config..."
# Uncomment to generate new node configurations
talhelper genconfig


echo "verifying config..."
talhelper validate talconfig
}
export -f regen

bootstrap_talos(){

  echo "Bootstrapping TalosOS Cluster..."
  echo "Applying TalosOS Cluster config to cluster ..."
  if [ "$SINGLENODE" = false ] ; then
    check_master
    talhelper gencommand --apply --extra-flags=--insecure | bash
  else
    talhelper gencommand --apply -n k8s-control-1 --extra-flags=--insecure | bash
  fi

    echo "Waiting for 3 minutes before bootstrapping..."
    sleep 180
    check_master

  # It will take a few minutes for the nodes to spin up with the configuration.  Once ready, execute
  talosctl bootstrap -n $MASTER1IP

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
  talhelper gencommand --apply -n k8s-control-1 | bash
  check_master
  prompt_yn
  if [ "$SINGLENODE" = false ] ; then
    echo "applying new operating system config to MASTER-B1..."
    talhelper gencommand --apply -n k8s-control-2 | bash
    check_master
    prompt_yn
    echo "applying new operating system config to MASTER-C1..."
    talhelper gencommand --apply -n k8s-control-3 | bash
    check_master
    prompt_yn
  fi
}
export -f update_talos_config

menu
