# project-talos
WIP project to provide Talos Linux example deployments and docs

## Requirements

### Masters

We build the masters using Raspberry Pi 4 nodes, these are cheap and relyable enough to function even production ready usecases.
The only challenge is to use either extremely high relyability SD-cards.
Part of this decision is the low cost of entry, while still offering ample performance, as these nodes will only run the kubernetes master services.

#### Part List:

3x Raspberry Pi 4 4gb | 75 USD each | 225 USD total
3x Raspberry Pi Charger | 11 USD each | 33 USD total
3x Raspberry pi case with fan and heatsinks | 15 USD each | 45 USD total
3x Sandisk Max Endurance 64Gb SD-Card | 23 USD each | 69 USD total

Grand total for 3 master nodes: 372 USD
Total per node: 124 USD All inclusive

If you want to stick closer to Talos OS and Kubernetes official specification advice, you can opt to go for the Raspberry Pi 4 8gb with Sandisk Max Endurance 128gb (or external ssd) instead.

### Workers

Generally every device with decent networking and some local storage can be deployed as worker. For this reason we've opted to append the Talos OS Configuration with as many of the optional drivers as possible.

#### Storage

We've chosen to, by default, also use the Talos OS system disk as local storage target for LocalPV.
At the same time, we will also use this disk for storing CEPH DB and WAL data for any mechanical harddrives used with Ceph.

This ensures users don't have to mess-around with selecting the right disks for storage and everything "just works" out-of-the-box
The consequence of this, is that we have the following minimum system requirements for the Talos OS system disk for all workers:

- Flash storage (or virtualised equivalent)
- Minimum 256GB
- Recommended 568GB
- PowerLoss Protection(PLP) recommended, Required when using Ceph.

#### Networking

We advice a minimum of 1Gbe networking 
When using networked storage, we recommend 2.5Gbe networking instead to prevent storage bottlenecking communications

When using Ceph, however, we advice a minimum of 2.5Gbe networking and recommend 10Gbe networking to prevent issues with Ceph and containers fighting for bandwidth

#### Virtualised workers

Our default worker configuration ships with qemu guest additions installed already.
However, to prevent issues with workers fighting for resources we would heavily advice against running multiple workers on the same host system.
On top of that, we also would advice against running Ceph OSDs with virtualised nodes and keep those nodes limited to local-storage, networked storage using democratic-CSI or storage from other workers running Ceph.


## Getting Started

### Setting up requirements

**windows**

- Install talosctl: `choco install talosctl`
- Install fluxcli: `brew install fluxcd/tap/flux`
- Install age: `choco install age.portable`

**Linux**

- Install talosctl: `curl -sL https://talos.dev/install | sh`
- Install fluxcli: `brew install fluxcd/tap/flux`
- Install age: `brew install age`

## Building config

- edit build.sh and set the IP adresses as you want them
- run `sh build.sh` to generate initial config


## Booting the nodes

- Set static DHCP adresses on your router to the IP adresses you defined in build.sh
- Boot all nodes from intall media

## Applying config

- run `sh apply.sh`