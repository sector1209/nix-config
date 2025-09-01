# configuration for spiros

{
  modulesPath,
  config,
  pkgs,
  inputs,
  outputs,
  ...
}:
let

  hostname = "spiros";
  user = "dan";

in
{

  imports = [
    ./hardware-configuration.nix
    ./docker.nix
  ];

  boot.loader.systemd-boot.enable = true;

  networking.hostName = hostname;

  roles = {

    technitium-dns = {
      enable = true;
      hostName = "dns2";
    };

    nginx.enable = true;

  };

  services.tailscale = {
    useRoutingFeatures = "server";
    extraSetFlags = [ "--advertise-exit-node" ];
  };

  # Reverse proxy for home jellyfin
  services.nginx.virtualHosts."jellyfin.danmail.me" = {
    enableACME = true;
    acmeRoot = null;
    addSSL = true;
    locations."/" = {
      proxyPass = "http://jellyfin.c.danmail.me:80";
    };
  };

  roles.services.beszel-agent.enable = true;

  users.users.dan.uid = 1000;

  system.stateVersion = "24.11";

}
