#!/bin/bash

export SINGLENODE=false

# Always True when SINGLENODE is true
export MASTERWORKLOADS=false

export VIP=192.168.10.100
export MASTER1=192.168.10.110

# Only used when SINGLENODE is false
export MASTER2=192.168.10.120
export MASTER3=192.168.10.130

# TODO: Move token to prompt
export GITHUB_TOKEN="<your-token>"
export GITHUB_USER="<your-username>"
export GITHUB_REPOSITORY="<your-repository-name>"
