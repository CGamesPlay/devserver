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

### Tips for MacOS users

I additionally wrap the `devserver` script in my own custom scripts to make it easier to use on my configuration. I use fish shell, and I've manually set up WireGuard with the name "Dev Server".

```fish
function start_freelancing
  echo "Starting Dev Server"
  devserver start || return $status
  echo "Connecting VPN"
  networksetup -connectpppoeservice "Dev Server"
  # Wait for WireGuard service to initialize. Does not verify connection.
  while ! scutil --nc status "Dev Server" | head -1 | grep -q Connected; sleep 1; end
  echo "Verifying connection"
  for i in (seq 1 60)
    if ping -c 1 10.254.0.1 > /dev/null
      break
    end
  end
  if ! ping -c 1 10.254.0.1 > /dev/null
    echo "WireGuard is not connected"
    return 1
  end
  echo "Waiting for docker"
  while ! nc -z 10.254.0.1 2375; sleep 1; end
  echo "Setting DOCKER_HOST (universally)"
  set -Ux DOCKER_HOST tcp://10.254.0.1:2375
end

function stop_freelancing
  echo "Unsetting DOCKER_HOST universally"
  set -Ux DOCKER_HOST
  echo "Disconnecting VPN"
  networksetup -disconnectpppoeservice "Dev Server"
  echo "Stopping Dev Server"
  devserver stop
end
```

## Features

**SSH** is exposed on the default port (22).

**Wireguard** is exposed on port 51820. The client configuration is located at `~/wg0.conf`. The droplet will be `10.254.0.1`  on the VPN.

**Docker** is exposed over TCP with `DOCKER_HOST` set to `tcp://10.254.0.1:2375`.

## TODO

- [ ] Improve the SSH key configuration.
- [ ] Automatic shutdown after inactivity.
- [ ] Workflow for docker-compose / easily created per-project docker images.
- [ ] Integration with LetsEncrypt and nginx proxy.
