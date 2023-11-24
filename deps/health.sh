#!/usr/bin/sudo bash

prompt_yn_node () {
read -p "Healthcheck failed, is the currently updated node working correctly? please verify! (yes/no) " yn

case $yn in
    yes ) echo ok, we will proceed;;
    no ) echo exiting...;
        exit;;
    y ) echo ok, we will proceed;;
    n ) echo exiting...;
        exit;;
    * ) echo invalid response;
        prompt_yn_node;;
esac
}
export prompt_yn_node

check_health(){
 PREBOOTSTRAP=false
 if [ ! -z "$1" ]; then
   echo "Waiting for node to be online on ip ${1}..."
   sleep 5
   while ! ping -c1 ${1} &>/dev/null; do :; done
   if [ -f BOOTSTRAPPED ]; then
     echo "Checking Cluster Health..."
     talosctl health --talosconfig clusterconfig/talosconfig -n ${VIP} >/dev/null 2>&1 || prompt_yn_node
   fi
 else
   if [ -f BOOTSTRAPPED ]; then
     echo "Checking Cluster Health..."
     talosctl health --talosconfig clusterconfig/talosconfig -n ${VIP} || exit 1
   elif $PREBOOTSTRAP; then
     echo "Checking Cluster Health..."
     talosctl health --talosconfig clusterconfig/talosconfig -n ${VIP} || exit 1
   fi
 fi
}
export check_health
