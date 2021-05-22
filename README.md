# minaprotocol docker-compose bundle All-In-One

- Mina protocol nodes (mainnet, devnet)
- Mina archive nodes
- PostgreSQL database
- Sidecar (for mainnet only)
- [Snark Worker start/stop script](https://github.com/c29r3/mina-snark-stopper)
- [Performance Dashboard](https://github.com/dsrvlabs/mina-performance-dashboard)

Project URL: [mina.run](https://mina.run/)

-----
    Inspired by Mina - the world's lightest blockchain | minaprotocol.com
    Send some candies if you found this helpful to author's wallet:
    B62qrQ4m3KNeNBsC86AW1vyXxEs32NbG2pDA2mdvCq5erxLqftVyZTj
-----

## Disclaimer

The information provided is not affiliated, associated, authorized, or endorsed by [O(1)Labs](https://minaprotocol.com/about) or any of its subsidiaries or its affiliates. You should consider the repository as unoffical resource completely unrelated to O(1)Labs.

----

## Table of contents

* [Prerequisites](#prerequisites)
* [Docker installation](#docker-installation)
* [Docker-compose installation](#docker-compose-installation)
* [Mina node installation](#mina-node-installation)
* [How to use mina in the docker](#how-to-use-mina-in-the-docker)
* [Node Performance Dashboard](#node-performance-dashboard)
* * [Enabling Performance Dashboard in the docker-compose](#enabling-performance-dashboard-in-the-docker-compose)
* * [Configuring Performance Dashboard](#configuring-performance-dashboard)
* [Extra scripts (mina-snark-stopper)](#extra-scripts)
* [Upgrading](#upgrading)
* [Known issues](#known-issues)
* * [Mina Sidecar](#mina-sidecar)
* [References](#references)

-----

This project was born due to desire to have a quick and easy mina daemon installation way and make a mina node launch as easy as possible. [The official documentation](https://minaprotocol.com/docs/connecting) is clear for technicians, but sometimes it's a bit hard to figure out for those who never worked with Linux and Docker what to do there.

Since Mina engineers provided a docker build of all Mina's parts, we'll make the installation as easy as pie.  The docker-compose in this repo contains everything that need to run Mina daemon successfully with no pain.

Using provided `docker-compose.yml` it's possible to launch: 

- two `mina daemon` different containers for `mainnet` and `devnet` separately using different daemon port bindings (devnet disabled by default);
- two `mina archive` containers (for `mainnet` and `devnet` containers);
- postgresql container to be used by `mina archive` containers as a database server;
- `mina sidecar` to collect and send out node uptime stats;
- there is also included "mina-snark-stopper" script and "Node Performance Dashboard".

Note: for both networks (mainnet and devnet) there is used same wallet (key file) being used in the folder `keys/`. If need, to use different keys, it's possible to separate the `keys/` folder, e.g.: `keys/devnet/` and `keys/mainnet/`.

## Prerequisites

As stated [in the official documentation](https://minaprotocol.com/docs/getting-started), to run mina node we have to acquire a Linux server box, with:

- at least a 8-core processor
- at least 16GB of RAM

It could be simple VPS/VDS obtained from Google Cloud, DigitalOcean, Vultr, etc. Of course, we can run Mina on our MacBook, Windows PC, but I wouldn't recommend to use your own working laptop or desktop station for such purpose. Mina node must be available online 24/7 to be able produce blocks or sell snarks uninterruptedly. I believe the only use case to use your working laptop/computer for Mina - is a "cold wallet".

This docker-compose bundle designed to be launched in the Linux or any other \*nix like box.

For the docker installation you can select any Linux distribution, although the docker-compose bundle created and tested using Docker in **Debian 10.x Linux**.

To continue, we assume that you have obtained a Linux server, you're connected to the server ssh terminal and you have root privileges. Also, you should have your server public IP address. You may have existing Mina wallet, or you can create new one.

On the first stage, if your server has no installed **docker** and **docker-compose**, you should install it. 

If you're connected to the server ssh terminal as regular (non-root) user, then become root with `sudo -i` and then proceed.

Install required packages `git` and `curl`:

For Debian/Ubuntu Linux:

```
apt -y install curl git
```
For CentOS/RedHat Linux:

```
yum -y install curl git
```

## Docker installation

Run these commands from terminal in order to install Docker:

```
curl -sSL https://get.docker.com/ | CHANNEL=stable sh
systemctl enable docker.service
systemctl start docker.service
```

## Docker-compose installation

Run these commands from terminal in order to install Docker-compose:

```
curl -sL https://github.com/docker/compose/releases/download/1.28.6/docker-compose-$(uname -s)-$(uname -m) > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```
Note: currently the most recent version of docker-compose is **1.28.6**. Later it may become updated. However, provided docker-compose.yml is fine with current version.

## Mina node installation

Assuming you're going to store your docker-compose project in the folder `/docker/mina`, run the next commands:

```
mkdir /docker
git clone https://github.com/trancemind/mina-docker-compose /docker/mina
```
Before to start Mina daemon, make sure that your have created a mina wallet and so you have a public/private key pair in the folder `keys/`.

You can use a `create_wallet` script from the `scripts/` folder to generate a new wallet. Simply launch it in the terminal:

```
/docker/mina/scripts/create_wallet
```
During the wallet creation, type your password for the private key. Don't use special chars to avoid any weird docker's error. Once the wallet created, write down your public key and don't forget your private key password.

Alternatively you may want to use your existing wallet. In this case, you have to upload your public and private key files in the docker-compose folder `keys/`.

Next, create docker-compose environment config file, using provided example. Just copy `m.conf.example` to `m.conf` and change variables on your own. Also, you should create `daemon.json` file, otherwise, the docker container won't start.

```
cd /docker/mina
cp m.conf.example m.conf
cp etc/mainnet/daemon.json.example etc/mainnet/daemon.json
cp etc/devnet/daemon.json.example etc/devnet/daemon.json # If you going to use devnet container
```

Make sure that your key folder and your wallet private key is a user-accessible only! **This is important!**

```
chmod 700 keys/
chmod 600 keys/my-wallet
```

Open `m.conf` config file using editor, e,g:

```
nano m.conf
```

Read instructions in the file and perform necessary changes. Set:

- your server public IP address in MINA_PUBlIC_IP;
- your wallet public key in MINA_PUBLIC_KEY;
- your private key password for MINA_PRIVKEY_PASS (*and, yes, don't use special chars in your password to avoid any weird docker's error*);
- if you want to payout rewards from BP to another wallet, change COINBASE_PUBLIC_KEY respectively;
- you can change your WALLET_NAME to something yours, but this is not mandatory.

These are minimal config options you have to change in order to start docker-compose. However, you can check other options as well and change them on own mind, if you know what to do.

**NOTE**: there is both BP and SW enabled by default. Usually, it's not recommended since if you're targeted to produce block, you'd better disable snark worker, because SW is pretty much consuming server's CPU time.

In order to disable snark worker, remove `--run-snark-worker ${MINA_PUBLIC_KEY}` out from the `DAEMON_OPTS_MAINNET` variable.

Once you finished to edit `m.conf` file, you're ready to launch your mina node. Make sure that your current directory is a docker-compose dir:

```
cd /docker/mina
```
and run:

```
docker-compose up -d
```
You should see docker's diagnostic messages, while docker downloading images and creating containers.

Once the operation is completed, check if everything went well:

```
docker-compose ps
```
You should see a list of mina containers. Check status for each container. All containers must be "Up".

In case if something wrong and your containers won't up, run a logs flow in your terminal to see error messages. In most cases it's clear right away what's wrong there. You can run logs displaying for certain container:

```
docker-compose logs -f mainnet
```

To check mixed logs from all containers:
```
docker-compose logs -f
```
Press Crtl-C to interrupt the docker-compose task and return back to the server shell.

## How to use mina in the docker

While using docker, you can either execute from terminal `docker-compose exec [container_name] bash` in order to login inside container to perform further operations or you can send commands to the mina client via `docker-compose exec [container_name] mina client [SUBCOMMAND]`. It's up to you what is more handy.

If everything was fine on the installation step, you can enter inside the docker container and check if the mina client connected to Peers:

```
docker-compose exec mainnet bash
mina client status
```
or:

```
docker-compose exec mainnet mina client status
```
or even:

```
watch -n 5 'docker-compose exec mainnet mina client status'
```
Press Ctrl-C to interrupt the docker-compose task and return back to the server shell.

Any other `mina client` and `mina advanced` commands are also available inside the docker container. E.g.:

```
mina accounts import -privkey-path /keys/my-wallet
mina account unlock --public-key $MINA_PUBLIC_KEY
mina client set-snark-work-fee 2.000000000
```
and so on.

----
## Node Performance Dashboard

Developed by [DSRVLabs](https://www.dsrvlabs.com/en/)

Original repo: https://github.com/dsrvlabs/mina-performance-dashboard

> Mina Performance Dashboard is a performance monitoring tool for Mina Protocol. It provides two functions, collecting and visualizing Block Producers' and Snarkers' performance data.

It also helps to monitor basic metrics of your server and detect any possible bottlenecks in time being.

### Enabling Performance Dashboard in the docker-compose

The Dashboard contains three additional docker images: `Prometheus`, `Node Exporter` and `Grafana`. It's disabled by default in the `m.conf` configuration file. In order to enable, there is need to add another profile, named `dashboard`, to the `COMPOSE_PROFILES` variable. It may look like this:

```
COMPOSE_PROFILES=mainnet,dashboard
```
Make sure that `mainnet` container is running with flag `--metrics-port 6060`. Check `DAEMON_OPTS_MAINNET` in the `m.conf.example` for reference. 

-----

**PLEASE, NOTE:** if you're already running `mainnet` (mina daemon) container without flag `--metrics-port`, your changes made in the `DAEMON_OPTS_MAINNET` variable will cause `mainnet` container restart on `docker-compose up -d`. If your mina daemon uptime is on top for you, then probably it would be good idea to delay the Dashboard setup until the next planed server maintenance or restart.

-----

Also, make sure that your `m.conf` configuration files contains:

```
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
```
See `m.conf.example` for reference.

Important step is to setup correct permissions on the folder for Grafana and Prometheus database:

```
chmod 777 ./db/grafana ./db/prometheus
```

That's all what you have to change to run the Dashboard successfully for your Mina node. However, if you want to play with extra vars, you can take a look to the prometheus configuration file, located in `./etc/dashboard/prometheus-mina.yml`.

Update your docker-compose to launch Dashboard services:

```
cd /docker/mina
docker-compose up -d
```
Once all new containers deployed and launched, check logs to make sure that everything is running smoothly:

```
docker-compose ps
docker-compose logs --tail=30 prometheus
docker-compose logs --tail=30 node_exporter
docker-compose logs --tail=30 grafana
```
Check your access to the Grafana web interface. Follow by URL: `http://YOU_SERVER_IP_ADDRESS:3000/` You should get Grafana's login screen. 

> You can login to Grafana with username admin and default password admin. After you connect to Grafana for the first time, you will see a screen to set new password for your account.

### Configuring Performance Dashboard

You have to configure your Grafana to get a metrics Dashboard. The configuration has two steps: adding data source and dashboard template import.

Add new datasource of type "Prometheus". Go to `Configuration > Data Sources > Add data source > Prometheus`. Set:

- Name: `mainnet`
- URL: `http://prometheus.local:9090`
- Access: `Server (default)`

<p align="center"><img width="629" alt="dashboard_figure_01" src="https://user-images.githubusercontent.com/80857349/111788085-5a044c80-88c8-11eb-9a22-95e2c87f688f.png"></p>

Click `Save and Test`

If the datasource configured correctly, you should get response:

<p align="center"><img width="363" alt="dashboard_figure_02" src="https://user-images.githubusercontent.com/80857349/111788092-5b357980-88c8-11eb-849b-b0cb04aa2cc0.png"></p>

Next, you should add a dashboard from JSON template. Go to `Create > Import` menu item:

<p align="center"><img width="230" alt="dashboard_figure_03" src="https://user-images.githubusercontent.com/80857349/111788094-5bce1000-88c8-11eb-8c95-5affc22d9043.png"></p>

You can import the Dashboard template easily by entering Dashboard ID in the Grafana repository.

The ID is `12840`. Type it and click `Load`.

<p align="center"><img width="705" alt="dashboard_figure_04" src="https://user-images.githubusercontent.com/80857349/111788097-5bce1000-88c8-11eb-87ec-fc5a67d8d524.png"></p>

Alternatively, you can downlod JSON file from https://github.com/dsrvlabs/mina-performance-dashboard/blob/master/grafana-json-model.json and upload to Grafana.

Once Dashboard config loaded in your Grafana, you have to import it.

<p align="center"><img width="697" alt="dashboard_figure_05" src="https://user-images.githubusercontent.com/80857349/111788100-5c66a680-88c8-11eb-91ad-54a58f2d7c09.png"></p>

Select:
- `Folder` -> General
- `Prometheus-Coda` -> mainnet (or another name you selected for datasource)

Click `Import` and the Dashboard will be become on your screen.

You can change advanced settings through the web interface. Once you're all set, click `Save` icon in the top-right.

<p align="center"><img width="223" alt="dashboard_figure_06" src="https://user-images.githubusercontent.com/80857349/111788104-5cff3d00-88c8-11eb-86e5-8975b641df37.png"></p>

In few minutes you should see some data arrived from the datasource to Grafana Dashboard.

----
## Extra scripts

**[mina-snark-stopper](https://github.com/c29r3/mina-snark-stopper)** - useful script, created by [Staketab.com](https://staketab.com), purposed to stop and start snark worker when needed.

> This tool can be useful for Mina validators who run node at same time as block producer and snark worker. 
> Worker can take up all processor time, which negatively affects block producer. 
> When less than STOP_WORKER_BEFORE_MIN minutes remain before the next proposal, the script disconnects the worker and starts it after STOP_WORKER_FOR_MIN minutes.

This tool now integrated with mina-docker-compose and you can run this as additional container in the bundle.

#### mina-snark-stopper installation

This tool is disabled by default. To enable, you should add additional profile in the `m.conf`. In the line `COMPOSE_PROFILES=` add additional profile `snark-stopper`, separated by comma. It may look like this:

```
COMPOSE_PROFILES=mainnet,snark-stopper
```
Create mina-snark-stopper configuration file:

```
cp etc/snark-stopper/config.yml.example etc/snark-stopper/config.yml
```
Change few options in the `etc/snark-stopper/config.yml`

- `WORKER_PUB_KEY` - set your mina public key. The key must be equal to `MINA_PUBLIC_KEY` in the `m.conf`
- `WORKER_FEE` - set your snark worker fee. This value worth to keep the same as `SNARK_FEE` in the `m.conf`
- Make sure that the `GRAPHQL_PORT` is equal to `MINA_PORT_GQL` in the `m.conf`. Otherwise mina-snark-stopper won't be able to connect to your mina daemon.
- Change other values at your discretion.

Finally, create empty log file:

```
touch logs/snark_stopper.log && chmod 666 logs/snark_stopper.log
```
Update your docker-compose to launch mina-snark-stopper:

```
cd /docker/mina
docker-compose up -d
```
Check container logs after launch:

```
docker-compose logs -f --tail=10 mainnet_snark_stopper
```
The output should be similar to this:

```
Attaching to mina_mainnet_snark_stopper_1
mainnet_snark_stopper_1  | version 1.2.5
mainnet_snark_stopper_1  | |2021-03-18 23:08:08,758| Snark-stopper launched
mainnet_snark_stopper_1  | Worker public key:  B62qrGej6d5bZiMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
mainnet_snark_stopper_1  | Worker fee:         1000000024
mainnet_snark_stopper_1  | Check period(sec):  180
mainnet_snark_stopper_1  | Stop before(min):   10
mainnet_snark_stopper_1  | https://github.com/c29r3/mina-snark-stopper
mainnet_snark_stopper_1  | http://staketab.com/
mainnet_snark_stopper_1  |
mainnet_snark_stopper_1  | |2021-03-18 23:08:08,842| 🙀 No proposal in this epoch
```

## Upgrading

##### Warning:

> The upgrading process is causing mina daemon container restart, however, this is very important to keep your mina daemon at the most recent version to avoid known bugs and possible security issues. Do not neglect the upgrade if available.

You can upgrade your mina docker-compose installation **manually**, or using provided `update.sh` **script**.

**Using `update.sh`** you have to perform the next easy steps:

```
cd /docker/mina
git pull
chmod +x update.sh
./update.sh
```

In order to **manually upgrade** your current running mina docker-compose installation, at first, you should get the most recent changes from the `mina-docker-compose` repo:

```
cd /docker/mina
git pull
```

Once done, edit your `m.conf` configuration file and replace image versions. See examples from the most recent version of `m.conf.example` file.

Commonly, it would have to compare (and replace by need):

- `MINA_TAG_MAIN` - latest version tag is **1.1.5-a42bdee**
- `MINA_TAG_ARCH` - latest version tag is **1.1.5-a42bdee**; (required, if you're running mina archive container)
- `MINA_TAG_DEV` - latest version tag is **1.0.5-68200c7**; (required, if you're running mina devnet container) 
- Latest Mina Sidecar version: **[1.1.6-386c5ac](https://hub.docker.com/r/minaprotocol/mina-bp-stats-sidecar/tags)**

Once you've done with `m.conf` modifications, save the file and then pull new docker images, upgrade and restart your containers:

```
cd /docker/mina
docker-compose pull
docker-compose up -d
```
Check containers logs and `mina client status` to make sure that everything restarted successfully.

## Known issues

### Mina Sidecar

Sidecar is not launching successfully right after the first start, when the .mina-config folder is not yet synced, and doesn't contain reliable data from the network. When launching sidecar first time you can see errors:

```
docker-compose logs -f mainnet_sidecar
...
mainnet_sidecar_1  | INFO:root:Fetching block 221...
mainnet_sidecar_1  | ERROR:root:Response seems to be an error! {"errors":[{"message":"Could not find block in transition frontier with height 221","path":["block"]}],"data":null}
mainnet_sidecar_1  | Traceback (most recent call last):
mainnet_sidecar_1  |   File "/opt/sidecar.py", line 149, in <module>
mainnet_sidecar_1  |     block_data = fetch_block(current_finalized_tip)
mainnet_sidecar_1  |   File "/opt/sidecar.py", line 107, in fetch_block
mainnet_sidecar_1  |     raise Exception("Response seems to be an error! {}".format(response_body))
mainnet_sidecar_1  | Exception: Response seems to be an error! {"errors":[{"message":"Could not find block in transition frontier with height 221","path":["block"]}],"data":null}
mainnet_sidecar_1  | ERROR:root:Sleeping for 30s and trying again
```

To fix this you just have to wait until mina daemon got its first "Synced" status. Check the status like this:

```
docker-compose exec mainnet mina client status | egrep "^Sync status:"
```
Once you get:

```
Sync status: Synced
```
You should **restart sidecar**:

```
docker-compose restart mainnet_sidecar
```
Then check logs again:

```
docker-compose logs -f --tail 10 mainnet_sidecar
```
You should see something like this:

```
mainnet_sidecar_1  | INFO:root:Found /etc/mina-sidecar.json on the filesystem, using config file
mainnet_sidecar_1  | INFO:root:Starting Mina Block Producer Sidecar
mainnet_sidecar_1  | INFO:root:Fetching block 517...
mainnet_sidecar_1  | INFO:root:Got block data
mainnet_sidecar_1  | INFO:root:Finished! New tip 517...
```
This meaning your sidecar is working successfully.

## References

- [Keypair generation](https://minaprotocol.com/docs/keypair)
- [Connect to the Network](https://minaprotocol.com/docs/connecting)
- [Archive Node](https://minaprotocol.com/docs/advanced/archive-node)
- [Node Status Reporting](https://minaprotocol.com/docs/advanced/node-status)
- [Mina snark-worker start/stop script](https://github.com/c29r3/mina-snark-stopper)
- [Performance Dashboard](https://github.com/dsrvlabs/mina-performance-dashboard)
- [Learn more about Mina with "Awesome Mina"](https://github.com/nerdvibe/awesome-mina)

## Donate

If you found this project helpful and this docker-compose bundle has saved a lot hours for you, please, consider some Mina donations for the author. You can just send few minas to:

`B62qrQ4m3KNeNBsC86AW1vyXxEs32NbG2pDA2mdvCq5erxLqftVyZTj`

It would be an excellent incentive for the author to continue this project.

-----

Last update: 2021-05-22
