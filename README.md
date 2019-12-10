# Personal Dev Server

The idea is to build a cloud VPS suitable for doing development on. Features:

- Beefy machine to be used as a docker host
- Wireguard VPN to utilize provided services
- Local script to start up and shut down server

## Usage

**Initial configuration**

1. Install `doctl` and use `doctl auth init` to tie to your [DigitalOcean](https://www.digitalocean.com) account.
2. Copy `.env.local` to `.env` and edit it to suit your needs.
3. Make sure the domain name you chose is set up in the DigitalOcean dashboard.
4. Run `./devserver init` to create a new droplet for use as a devserver and set up the software.
5. The script drops `wg0.conf` into the current directory. Use that to connect to wireguard.
6. Set `DOCKER_HOST` to `tcp://10.254.0.1`.
7. Run `docker` commands normally.

**Shut down server when not in use**

To save on costs, you can snapshot the server and shut it down.

1. Run `./devserver stop` on your local machine.

**Restoring a server from snapshot**

Recreate and reconnect to a stopped server.

1. Run `./devserver start` on your local machine.
2. Reconnect to wireguard.
3. Set your `DOCKER_HOST` back to `10.254.0.1`.

## Features

**SSH** is exposed on the default port (22).

**Wireguard** is exposed on port 51820. The client configuration is located at `~/wg0.conf`. The droplet will be `10.254.0.1`  on the VPN.

**Docker** is exposed over TCP with `DOCKER_HOST` set to `tcp://10.254.0.1:2375`.

**NFS** exposes `/home/ubuntu` on `10.254.0.1`. Mount from Mac OS using `nfs://10.254.0.1/home/ubuntu`.

## TODO

- [ ] Automatic shutdown after inactivity.
- [ ] Workflow for docker-compose / easily created per-project docker images.
- [ ] Integration with LetsEncrypt and nginx proxy.
