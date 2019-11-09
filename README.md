# Personal Dev Server

The idea is to build a cloud VPS suitable for doing development on. Features:

- Beefy machine to be used as a docker host
- Wireguard VPN to utilize provided services
- File sharing host for hosting local projects
- Per-project custom docker images
- Local script to start up server
- Automatic shutdown after inactivity
- Run as cloud VPS or local virtual machine

## Usage

**Initial configuration**

1. Install `doctl` and use `doctl auth init` to tie to your [DigitalOcean](https://www.digitalocean.com) account.
2. Copy `.env.local` to `.env` and edit it to suit your needs.
3. Run `provision.sh` to create a new droplet for use as a devserver and set up the software.
4. The script drops `wg0.conf` into the current directory. Use that to connect to wireguard.
5. Set `DOCKER_HOST` to `tcp://10.254.0.1`.
6. Run `docker` commands normally.

**Shut down server when not in use**

To save on costs, you can snapshot the server and shut it down.

1. Run `shutdown.sh` on your local machine.

**Restoring a server from snapshot**

Recreate and reconnect to a stopped server.

1. Run `start.sh` on your local machine.
2. Reconnect to wireguard.
3. Set your `DOCKER_HOST` back to `10.254.0.1`.

## TODO

- [ ] Automatic shutdown after inactivity.
- [ ] Samba filesharing to use as docker volumes.
- [ ] Workflow for docker-compose / easily created per-project docker images.
- [ ] Integration with LetsEncrypt and nginx proxy.