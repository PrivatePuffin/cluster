# Clustertool

Easy deployment tooling and documentation for deploying TalosOS and/or FluxCD

## Limitations

Our default talconfig.yaml file, makes a lot of assumptions for quick deployment. You're free to adapt your version of it as you please.
By default you:

- Should not have more than 1 network adapter on controlplane nodes
- Should not have more than 1 Disk on controlplane nodes
- Should not have more than 1TB space on said disk on controlplane nodes

## Requirements

### Masters

We build the masters using Raspberry Pi 4 nodes, these are cheap and relyable enough to function even production ready usecases.
The only challenge is to use either extremely high relyability SD-cards.
Part of this decision is the low cost of entry, while still offering ample performance, as these nodes will only run the kubernetes master services.

#### Minimum Specs

4 Threads or vCores
4GB Ram
64GB storage
1GBe Networking

#### Recommended specs

4 Cores
8GB Ram
128GB storage
1GBe Networking

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

#### Storage (TBD)

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

## TalosOS synopsys

TalosOS is a bare-bones linux distribution to run kubernetes clusters.
It gets build/installed/maintained based on configuration files.

To more-easily generate those, we use another tool: talhelper.
When using clustertool, configuration mangement goes like this:

clustertool -> talhelper -> talosctl -> node(s)

---

## Getting Started

### Setting up requirements

#### windows

Please run this in a WSL Linux (Preferably Debian) shell instead of directly on windows.
DO NOT use a GIT folder checked-out on windows, on the WSL. Ensure you git-clone or git-checkout the folder on WSL when using it in WSL!

#### Linux

**Required External Dependencies**

- curl
- GIT
- Bash
- Python3
- PIP3

**Other Dependencies**

- Ensure your local system time is 100% correct
- Run `sudo ./clustertool.sh` tool, install the other dependencies

#### Knowhow

- Running your own cluster is not easy, people make a living of this for a reason, this tool is just to make things easier/quicker, not to "take things out-of your hands".
- You understand kubectl enough to figure out basic commands
- You have at least some experience bugtracing errors in a kubernetes stack
- You have more than intermediate knowhow in networking and understand the difference between Layer 2 (DHCP, ARP) and Layer 3 Networking


## Preparations

- Create a Github Private access token with wide access to your repositories
- Fork the repo here, to your own github account: `https://github.com/truecharts/project-talos`
- Ensure your newly created fork(!) of the template repository is checked-out using GIT and you've cd'ed into this folder.
- edit `talenv.yaml` and set the settings as you want them
- edit `talconfig.yaml` and edit it to suit your cluster. We advice to keep the "worker" commented out, till your "controlplane" nodes are setup.
- Set static DHCP adresses on your router to the IP adresses you defined in `talconfig.yaml`

## ISO prep

We use pre-extended builds of TalosOS with additional drivers.
For ISO's we advice to use the following:

**Controlplane nodes:**

AMD64 ISO: https://factory.talos.dev/image/9239d3b817f4812ea68d11a2fc71b3cd192623a95f7f8d67d80baaa84f17c0df/v1.5.5/metal-amd64.iso

ARM64 ISO: https://factory.talos.dev/image/9239d3b817f4812ea68d11a2fc71b3cd192623a95f7f8d67d80baaa84f17c0df/v1.5.5/metal-arm64.iso

**workers:**

AMD64: https://factory.talos.dev/image/ae6f4bdea27db101ac59bacc1844267275f2778f4c5a9422609aebc4e0507eb1/v1.5.5/metal-amd64.iso

ARM64: https://factory.talos.dev/image/ae6f4bdea27db101ac59bacc1844267275f2778f4c5a9422609aebc4e0507eb1/v1.5.5/metal-arm64.iso

## Bootstrapping TalosOS on the cluster

- Run `sudo ./clustertool.sh` tool, generate cluster configuration
- **IMPORTANT**: safe the (content of) `age.agekey` somewhere **safe**, this is the encryption key to your cluster!
- Boot all nodes from the TalosOS install media
- SMC (such as the raspberry-pi) might need additional work, as explained in the TalosOS docs.
- Ensure all nodes have the IP adresses defined earlier
- Run `sudo ./clustertool.sh` tool, Apply and Bootstrap the TalosOS cluster
- Run `sudo ./clustertool.sh` tool, Encrypt your configuration
- Push your configuration to Github manually.

## Bootstrapping FluxCD
- Run `sudo ./clustertool.sh` tool, decrypt your configuration
- Run `sudo ./clustertool.sh` tool, Bootstrap FluxCD on your newly created cluster
