#!/usr/bin/sudo bash

source ./deps/encryption.sh
source ./deps/deploy-extras.sh
source ./deps/health.sh
source ./deps/approve-certs.sh
source ./deps/apply-kubeconfig.sh

export FILES

function parse_yaml_env {
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
   echo "$(tr -d '\r' < talenv.env)" > talenv.env
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

echo "Instaling Helm..."
curl -Ss https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash  || echo "installation failed..."

echo "Installing Kustomize"
rm -f kustomize && curl -Ss "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/kustomize/v5.2.1/hack/install_kustomize.sh" | bash  &&  mv kustomize /usr/local/bin/kustomize &&  chmod +x /usr/local/bin/kustomize || echo "installation failed..."

echo "Installing velerocli..."
curl -Ss https://i.jpillora.com/vmware-tanzu/velero! | bash > /dev/null || echo "installation failed..."

echo "Installing talhelper..."
#cur -Ssl https://i.jpillora.com/budimanjojo/talhelper! | bash > /dev/null || echo "installation failed..."
rm -f /usr/local/bin/talhelper || true
cp talhelper /usr/local/bin/talhelper &&  chmod +x /usr/local/bin/talhelper || echo "installation failed..."

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
    echo "$(tr -d '\r' < talenv.yaml)" > talenv.yaml
    parse_yaml_env talenv.yaml
}
export parse_yaml_env_all

checktime() {
here=$(date +%s)
here=${here%?}
world=$(curl -s "http://worldtimeapi.org/api/timezone/Europe/Rome" |jq '.unixtime')
world=${world%?}

# if [ ! "$here" = "$world" ] ; then
#   echo "ERROR, SYSTEM TIME INCORRECT"
#   exit 1
# fi
}
export checktime

title(){
  echo ""
}
export title


menu(){
    clear -x
    title
    echo -e "${bold}Available Utilities${reset}"
    echo -e "${bold}-------------------${reset}"
    echo -e "h)  Help"
    echo -e "1)  Install/Update Dependencies"
    echo -e "2)  Decrypt Data"
    echo -e "3)  Encrypt Data"
    echo -e "4)  (re)Generate Cluster Config"
    echo -e "5)  Bootstrap/Apply Talos Cluster Config"
    echo -e "6)  Upgrade Talos Cluster Nodes"
    echo -e "7)  Bootstrap FluxCD Cluster"
    echo -e "r)  Talos Cluster Recovery"
    echo -e "0)  Exit"
    read -rt 120 -p "Please select an option by number: " selection || { echo -e "${red}\nFailed to make a selection in time${reset}" ; exit; }


    case $selection in
        0)
            echo -e "Exiting.."
            exit
            ;;

        1)
            install_deps
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
            parse_yaml_env_all
            regen
            exit
            ;;
        5)
            parse_yaml_env_all
            apply_talos_config
            exit
            ;;
        6)
            parse_yaml_env_all
            upgrade_talos_nodes
            exit
            ;;
        7)
            parse_yaml_env_all
            bootstrap_flux
            exit
            ;;
        h)
            main_help
            exit
            ;;
        r)
            recover_talos
            exit
            ;;
        t)
            apply_talos_config
            exit
            ;;

    esac
    echo
}
export -f menu

regen(){
echo ""
echo "-----"
echo "Regenerating TalosOS Cluster Config..."
echo "-----"
# Prep precommit
echo "Update Pre-commit hooks..."
pre-commit install || echo "Install pre-commit hooks failed, continuing..."

echo "Ensuring schema is installed..."
talhelper genschema

# Generate age key if not present
if test -f "age.agekey"; then
  echo "Age Encryption Key already exists, skipping..."
else
  echo "Generating Age Encryption Key..."
  age-keygen -o age.agekey
  # Save an encrypted version of the age key, encrypted with itself
  cat age.agekey | age -r age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p > age.agekey.enc
fi

echo "Generating sops.yaml from template"
AGE=$(cat age.agekey | grep public | sed -e "s|# public key: ||" )
cat templates/.sops.yaml.templ | sed -e "s|!!AGE!!|$AGE|"  > .sops.yaml

echo "Creating agekey cluster patch..."
rm -rf patches/sopssecret.yaml || true
cat templates/sopssecret.yaml.templ | sed -e "s|!!AGEKEY!!|$( base64 age.agekey -w0 )|" > patches/sopssecret.yaml

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

echo "(re)generating chart-config"
rm -f ./cluster/main/flux-system/clustersettings.yaml || true
cp ./templates/clustersettings.yaml.templ ./cluster/main/flux-system/clustersettings.yaml
sed "s/^/  /" talenv.yaml >> ./cluster/main/flux-system/clustersettings.yaml
}
export -f regen

bootstrap_flux(){
 echo "Bootstrapping FluxCD on existing Cluster..."

 check_health

 echo "Ensure kubeconfig is set..."
 talosctl kubeconfig --force --talosconfig clusterconfig/talosconfig -n $VIP -e $VIP

 echo "Running FluxCD Pre-check..."
 flux check --pre > /dev/null
 FLUX_PRE=$?
 if [ $FLUX_PRE != 0 ]; then
   echo -e "Error: flux prereqs not met:\n"
   flux check --pre
   exit 1
 fi
 if [ -z "$GITHUB_TOKEN" ]; then
   echo "ERROR: GITHUB_TOKEN is not set!"
   exit 1
 fi

 echo "Executing FluxCD Bootstrap..."
 flux bootstrap github \
   --token-auth=false \
   --owner=$GITHUB_USER \
   --repository=$GITHUB_REPOSITORY \
   --branch=main \
   --path=./cluster/main \
   --personal \
   --network-policy=false

  FLUX_INSTALLED=$?
  if [ $FLUX_INSTALLED != 0 ]; then
    echo -e "ERROR: flux did not install correctly, aborting!"
    exit 1
  fi
}
export -f bootstrap_flux

apply_talos_config(){

  echo ""
  echo "-----"
  echo "Applying TalosOS Cluster config to cluster ..."
  echo "-----"

  while IFS=';' read -ra CMD <&3; do
    for cmd in "${CMD[@]}"; do
      name=$(echo $cmd | sed "s|talosctl apply-config --talosconfig=./clusterconfig/talosconfig --nodes=||g" | sed -r 's/(\b[0-9]{1,3}\.){3}[0-9]{1,3}\b'// | sed "s| --file=./clusterconfig/||g" | sed "s|main-||g" | sed "s|.yaml||g" | sed "s|--insecure||g")
      ip=$(echo $cmd | sed "s|talosctl apply-config --talosconfig=./clusterconfig/talosconfig --nodes=||g" | sed "s| --file=./clusterconfig/.*||g")
      echo ""
      echo "Applying new Talos Config to ${name}"
      $cmd -i 2>/dev/null || $cmd || echo "Failed to apply config..."
      check_health ${ip}
    done
  done 3< <(talhelper gencommand apply)
  echo ""
  echo "Config Apply finished..."


  if [ -f BOOTSTRAPPED ]; then
    echo "Cluster already bootstrapped, skipping bootstrap..."

    echo "Applying kubectl..."
    apply_kubeconfig
    echo "If kubectl is not yet available, please manually run: "
    echo "\"talosctl kubeconfig --talosconfig clusterconfig/talosconfig -n $VIP -e $VIP\""
    echo ""
  else
    echo ""
    echo "-----"
    echo "Bootstrapping TalosOS Cluster..."
    echo "-----"

    echo "Node online, bootstrapping..."
    # It will take a few minutes for the nodes to spin up with the configuration.  Once ready, execute
    talhelper gencommand bootstrap | bash || ( echo "Bootstrap Failed, retrying bootstrap procedure..." && apply_talos_config )

    export PREBOOTSTRAP=true
    check_health

    apply_kubeconfig

    echo "Deploying manifests..."
    approve_certs
    deploy_cni
    deploy_approver

    touch BOOTSTRAPPED
  fi

  echo "Bootstrapping/Expansion finished..."

}
export -f apply_talos_config

upgrade_talos_nodes () {

  talhelper gencommand upgrade --extra-flags=--preserve=true | bash

  check_health
  echo "updating kubernetes to latest version..."
   talhelper gencommand upgrade-k8s -n ${MASTER1IP}
  check_health
}
export upgrade_talos_nodes

if [[ $EUID -ne 0 ]]; then
    echo "$0 is not running as root. Try using sudo."
    exit 2
else
  checktime
  menu
fi
