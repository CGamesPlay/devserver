/// <reference path="./global.d.ts" />
import * as pulumi from "@pulumi/pulumi";
import * as DO from "@pulumi/digitalocean";
import * as fs from "fs";
import * as path from "path";
import { gzipSync } from "zlib";
import * as yaml from "js-yaml";

const config = new pulumi.Config();

function encodeFile(data: string | Buffer): string {
  return gzipSync(data).toString("base64");
}

const REGION = config.require("region") as DO.Region;
const INSTANCE_TYPE = "s-4vcpu-8gb";
const DOMAIN = config.require("domain");
// Either accept the SSH key ID in config and download it,
// OR automatically upload the SSH key.
const SSH_DIGITALOCEAN_KEYS = ["28316172"];
const SSH_PUBKEY_PATH = path.join(process.env.HOME!, ".ssh/id_rsa.pub");
const GB = 1024 * 1024 * 1024;

const cloudConfig = {
  apt_sources: {
    wireguard: { source: "ppa:wireguard/wireguard" }
  },
  packages: ["docker.io", "docker-compose", "wireguard"],
  mounts: [["LABEL=data", "/mnt/data"]],
  swap: { filename: "/swapfile", size: "auto", maxsize: 4 * GB },
  users: [
    {
      name: "ubuntu",
      groups: ["adm", "sudo", "docker"],
      shell: "/bin/bash",
      sudo: ["ALL=(ALL) NOPASSWD:ALL"],
      "ssh-authorized-keys": [fs.readFileSync(SSH_PUBKEY_PATH, "utf-8")]
    }
  ],
  disable_root: true,
  ssh_pwauth: "no",
  hostname: DOMAIN,
  write_files: [
    {
      path: "/etc/systemd/system/docker.service.d/override.conf",
      encoding: "gz+b64",
      content: encodeFile(`
[Unit]
After=wg-quick@wg0.service

[Service]
ExecStart=
# XXX - this is insecure! Any container with host network access can access the
# docker socket!
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://10.254.0.1:2375
`)
    },
    {
      path: "/etc/docker/daemon.json",
      encoding: "gz+b64",
      content: encodeFile(`{
  "data-root": "/mnt/data/docker"
}`)
    },
    {
      path: "/root/setup-ufw.sh",
      encoding: "gz+b64",
      permissions: "0755",
      content: encodeFile(
        fs.readFileSync(path.join(__dirname, "files/setup-ufw.sh"))
      )
    },
    {
      path: "/root/setup-wireguard.sh",
      encoding: "gz+b64",
      permissions: "0755",
      content: encodeFile(
        fs.readFileSync(path.join(__dirname, "files/setup-wireguard.sh"))
      )
    }
  ],
  runcmd: [
    "/root/setup-wireguard.sh",
    "/root/setup-ufw.sh",
    "service docker start"
  ]
};

const volume = new DO.Volume(
  "devserver-data",
  {
    region: REGION,
    size: 50,
    initialFilesystemType: "ext4",
    initialFilesystemLabel: "data"
  },
  { protect: true }
);

export const domain = DOMAIN;
export let ip: pulumi.Output<string> | null = null;

if (config.requireBoolean("running")) {
  const instance = new DO.Droplet(
    "devserver",
    {
      image: "ubuntu-20-04-x64",
      region: REGION,
      size: INSTANCE_TYPE,
      volumeIds: [volume.id],
      sshKeys: SSH_DIGITALOCEAN_KEYS,
      userData: `#cloud-config\n${yaml.safeDump(cloudConfig)}`
    },
    { deleteBeforeReplace: true }
  );

  const domain = new DO.Domain("domain", { name: DOMAIN });

  new DO.DnsRecord("root-record", {
    name: "@",
    domain: domain.name,
    type: "A",
    value: instance.ipv4Address
  });

  new DO.DnsRecord("sub-record", {
    name: "*",
    domain: domain.name,
    type: "A",
    value: instance.ipv4Address
  });

  ip = instance.ipv4Address;
}
