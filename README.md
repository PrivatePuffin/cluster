# project-talos
WIP project to provide Talos Linux example deployments and docs


## Getting Started

Setting up TalosCTL

**windows**

`choco install talosctl`

**Linux**

`curl -sL https://talos.dev/install | sh`

## Building config

- edit build.sh and set the IP adresses as you want them
- run `sh build.sh` to generate initial config


## Booting the nodes

- Set static DHCP adresses on your router to the IP adresses you defined in build.sh
- Boot all nodes from intall media

## Applying config

- run `sh apply.sh`