#!/bin/bash

source ./deps/encryption.sh

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

function install_deps {
cd deps
# These have automatic functions to grab latest release, keep it that way.
echo "Installing talosctl..."
curl -SsL https://talos.dev/install | sh > /dev/null || echo "installation failed..."

echo "Installing fluxcli..."
curl -Ss https://fluxcd.io/install.sh |  bash > /dev/null || echo "installation failed..."

echo "Installing kubectl..."
curl -SsLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" || echo "installation failed..."

echo "Installing velerocli..."
curl -Ss https://i.jpillora.com/vmware-tanzu/velero! | bash > /dev/null || echo "installation failed..."

echo "Installing talhelper..."
#cur -Ssl https://i.jpillora.com/budimanjojo/talhelper! | bash > /dev/null || echo "installation failed..."
cp talhelper /usr/local/bin/talhelper &&  chmod +x /usr/local/bin/talhelper

echo "Installing pre-commit..."
pip install pre-commit > /dev/null || pip install pre-commit --break-system-packages > /dev/null || echo "Installing pre-commit failed, non-critical continuing..."

echo "Installing/Updating Pre-commit hooks..."
pre-commit install --install-hooks > /dev/null || echo "installing pre-commit hooks failed, non-critical continuing..."

# TODO ensure these grab the latest releases.
echo "Installing age..."
curl -SsLO https://github.com/FiloSottile/age/releases/download/v1.1.1/age-v1.1.1-linux-amd64.tar.gz && tar -xvzf age-v1.1.1-linux-amd64.tar.gz > /dev/null &&  mv age/age /usr/local/bin/age &&  mv age/age-keygen /usr/local/bin/age-keygen &&  chmod +x /usr/local/bin/age /usr/local/bin/age-keygen

echo "Installing sops..."
curl -SsLO https://github.com/getsops/sops/releases/download/v3.8.1/sops-v3.8.1.linux.amd64 &&  mv sops-v3.8.1.linux.amd64 /usr/local/bin/sops &&  chmod +x /usr/local/bin/sops

echo "Finished installing all dependencies."
cd -
}
export install_deps

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

prompt_yn_node_node () {
read -p "Is the currently updated node working correctly? please verify! (yes/no) " yn

case $yn in
    yes ) echo ok, we will proceed;;
    no ) echo exiting...;
        exit;;
    * ) echo invalid response;
        prompt_yn_node_node;;
esac
}

title(){
  echo ""
}
export title


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
    echo -e "7)  Apply Talos Cluster Config"
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
            parse_yaml_env_all
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
            update_talos_config
            exit
            ;;

    esac
    echo
}
export -f menu

regen(){
# Prep precommit
echo "Installing/Updating Pre-commit hooks..."
pre-commit install --install-hooks || echo "installing pre-commit hooks failed, continuing..."

echo "Ensuring schema is installed..."
talhelper genschema

# Generate age key if not present
if test -f "age.agekey"; then
  echo "Age Encryption Key already exists, skipping..."
else
  echo "Generating Age Encryption Key..."
  age-keygen -o age.agekey
  AGE=$(cat age.agekey | grep public | sed -e "s|# public key: ||" )
  cat templates/.sops.yaml.templ | sed -e "s|!!AGE!!|$AGE|"  > .sops.yaml

  # Save an encrypted version of the age key, encrypted with itself
  cat age.agekey | age -r age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p > age.agekey.enc
fi

if test -f "patches/sopssecret.yaml"; then
  echo "Agekey Cluster patch already created, skipping..."
else
  echo "Creating agekey cluster patch..."
  cat templates/sopssecret.yaml.templ | sed -e "s|!!AGEKEY!!|$( base64 age.agekey -w0 )|" > patches/sopssecret.yaml
fi

if test -f "talsecret.yaml"; then
  echo "Talos Secret already exists, skipping..."
else
  echo "Generating Talos Secret"
  talhelper gensecret >>  talsecret.yaml
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
  while IFS=';' read -ra CMD; do
    for cmd in "${CMD[@]}"; do
      name=$(echo $cmd | sed "s|talosctl apply-config --talosconfig=./clusterconfig/talosconfig --nodes=||g" | sed -r 's/(\b[0-9]{1,3}\.){3}[0-9]{1,3}\b'// | sed "s| --file=./clusterconfig/||g" | sed "s|main-||g" | sed "s|.yaml --insecure||g")
      ip=$(echo $cmd | sed "s|talosctl apply-config --talosconfig=./clusterconfig/talosconfig --nodes=||g" | sed "s| --file=./clusterconfig/.*||g")
      echo "Waiting for node to come online on IP ${ip}..."
      while ! ping -c1 ${ip} &>/dev/null; do :; done
      echo "Applying new Talos Config to ${name}"
      $cmd
      sleep 30
      echo "Waiting for node to come online on IP ${ip}..."
      while ! ping -c1 ${ip} &>/dev/null; do :; done
    done
  done <<< "$(talhelper gencommand apply --extra-flags=--insecure)"

  echo "Waiting for 1 minute before bootstrapping..."
  sleep 60

  # It will take a few minutes for the nodes to spin up with the configuration.  Once ready, execute
  talosctl bootstrap --talosconfig clusterconfig/talosconfig -n $MASTER1IP

  echo "Waiting for 1 minute to finish bootstrapping..."
  sleep 60

  # It will then take a few more minutes for Kubernetes to get up and running on the nodes. Once ready, execute
  talosctl kubeconfig --talosconfig clusterconfig/talosconfig -n $VIP -e $VIP
  echo "Bootstrapping finished..."
}
export -f bootstrap_talos

bootstrap_flux(){
 echo "Bootstrapping FluxCD on existing Cluster..."

 echo "Safety Check: Waiting for response on ${VIP}..."
 while ! ping -c1 ${VIP} &>/dev/null; do :; done

 echo "Ensure kubeconfig is set..."
 talosctl kubeconfig --talosconfig clusterconfig/talosconfig -n $VIP -e $VIP

 echo "Running FluxCD Pre-check..."
 flux check --pre

 echo "Executing FluxCD Bootstrap..."
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
  while IFS=';' read -ra CMD; do
    for cmd in "${CMD[@]}"; do
      name=$(echo $cmd | sed "s|talosctl apply-config --talosconfig=./clusterconfig/talosconfig --nodes=||g" | sed -r 's/(\b[0-9]{1,3}\.){3}[0-9]{1,3}\b'// | sed "s| --file=./clusterconfig/||g" | sed "s|main-||g" | sed "s|.yaml||g")
      ip=$(echo $cmd | sed "s|talosctl apply-config --talosconfig=./clusterconfig/talosconfig --nodes=||g" | sed "s| --file=./clusterconfig/.*||g")
      echo "Applying new Talos Config to ${name}"
      $cmd
      echo "Waiting for node to come online on ip ${ip}..."
      sleep 20
      while ! ping -c1 ${ip} &>/dev/null; do :; done
      prompt_yn_node
    done
  done <<< "$(talhelper gencommand apply)"
}
export -f update_talos_config

upgrade_talos_nodes () {
  while IFS=';' read -ra CMD; do
    for cmd in "${CMD[@]}"; do
      name=$(echo $cmd | sed "s|talosctl upgrade --talosconfig=./clusterconfig/talosconfig --nodes=||g" | sed -r 's/(\b[0-9]{1,3}\.){3}[0-9]{1,3}\b'// | sed "s| --file=./clusterconfig/||g" | sed "s|main-||g" | sed "s|.yaml --preserve=true||g")
      ip=$(echo $cmd | sed "s|talosctl upgrade --talosconfig=./clusterconfig/talosconfig --nodes=||g" | sed "s| --file=./clusterconfig/.* --preserve=true||g")
      echo "Applying Talos OS Update to ${name}"
      echo "Waiting for node to come online on IP ${ip}..."
      while ! ping -c1 ${ip} &>/dev/null; do :; done
      $cmd
      echo "Waiting for node to come online on ip ${ip}..."
      sleep 20
      while ! ping -c1 ${ip} &>/dev/null; do :; done
      prompt_yn_node
    done
  done <<< "$(talhelper gencommand upgrade --extra-flags=--preserve=true)"

  echo "executing mandatory 1 minute wait..."
  sleep 60
  echo "updating kubernetes to latest version..."
  talosctl upgrade-k8s --talosconfig clusterconfig/talosconfig
}
export upgrade_talos_nodes

if [[ $EUID -ne 0 ]]; then
    echo "$0 is not running as root. Try using sudo."
    exit 2
else
  menu
fi
