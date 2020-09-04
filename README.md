# Personal Dev Server

The idea is to build a cloud VPS suitable for doing development on. Features:

- Beefy machine to be used as a docker host
- Wireguard VPN to utilize provided services
- Local script to start up and shut down server

## Usage

**Initial configuration**

1. Run `brew install pulumi` or install it through some other means.
2. Log in to pulumi, you can use `pulumi login --local` if you don't want the cloud services.
3. Run `yarn install` to install dependencies.
4. Run `./devserver init` to create a new droplet for use as a devserver and set up the software.
5. Run `./devserver start` to create the machine.
6. Use `wg0.conf` from the ubuntu home directory to connect to wireguard.
7. Set `DOCKER_HOST` to `tcp://10.254.0.1`.
8. Run `docker` commands normally.

**Shut down server when not in use**

To save on costs, you can delete the server, but leave the data volume running.

1. Run `./devserver stop` on your local machine.
2. Run `./devserver start` to recreate the machine when needed. The existing volume will be reused.

## Features

**SSH** is exposed on the default port (22).

**Wireguard** is exposed on port 51820. The client configuration is located at `~/wg0.conf`. The droplet will be `10.254.0.1`  on the VPN.

**Docker** is exposed over TCP with `DOCKER_HOST` set to `tcp://10.254.0.1:2375`.

## TODO

- [ ] Improve the SSH key configuration.
- [ ] Automatic shutdown after inactivity.
- [ ] Workflow for docker-compose / easily created per-project docker images.
- [ ] Integration with LetsEncrypt and nginx proxy.
