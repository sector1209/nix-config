# configuration for metrics monitoring proxmox container

{
  ...
}:
let

  hostname = "metrics";

in
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = hostname;

  roles = {

    proxmoxContainer.enable = true;

    gotify.enable = true;

    beszel-hub.enable = true;

    nginx.enable = true;

    influxdb.enable = true;

    grafanaStack.enable = true;

    uptime-kuma.enable = true;

  };

  system.stateVersion = "24.11";

}
