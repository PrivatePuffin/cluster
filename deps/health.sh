#!/bin/bash

check_health(){
 PREBOOTSTRAP=false
 if [ ! -z "$1" ]; then
   echo "Waiting for node to be online on ip ${1}..."
   sleep 5
   while ! ping -c1 ${1} &>/dev/null; do :; done
 fi
  if [ -f BOOTSTRAPPED ]; then
    echo "Talos Health Check not yet implemented..."
    sleep 5
    # talosctl health --control-plane-nodes 10.11.0.16,10.11.0.17,10.11.0.18 --worker-nodes 10.11.0.19,10.11.0.20,10.11.0.21 -n $*
  elif $PREBOOTSTRAP; then
    echo "Talos Health Check not yet implemented..."
    sleep 5
    # talosctl health --control-plane-nodes 10.11.0.16,10.11.0.17,10.11.0.18 --worker-nodes 10.11.0.19,10.11.0.20,10.11.0.21 -n $*
  fi
}
export check_health
