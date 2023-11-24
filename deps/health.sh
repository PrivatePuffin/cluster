#!/usr/bin/sudo bash

check_health(){
 PREBOOTSTRAP=false
 if [ ! -z "$1" ]; then
   echo "Waiting for node to be online on ip ${1}..."
   sleep 5
   while ! ping -c1 ${1} &>/dev/null; do :; done
 fi
  if [ -f BOOTSTRAPPED ]; then
    echo "Checking Health..."
    while ! ping -c1 ${VIP} &>/dev/null; do :; done
    talosctl health --talosconfig clusterconfig/talosconfig -n ${VIP} || exit 1
  elif $PREBOOTSTRAP; then
    echo "Checking Health..."
    while ! ping -c1 ${VIP} &>/dev/null; do :; done
    talosctl health --talosconfig clusterconfig/talosconfig -n ${VIP} || exit 1
  fi
}
export check_health
