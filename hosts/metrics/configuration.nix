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

    services.beszel-agent.enable = true;

    services.beszel-hub.enable = true;

    nginx.enable = true;

    influxdb.enable = true;

    grafanaStack.enable = true;

  };

  services.nginx.virtualHosts."beszel" = {

  };

  # configure nginx host
  services.nginx.virtualHosts = {
    "beszel.danmail.me" = {
      enableACME = true;
      acmeRoot = null; # i think this makes it use DNS-01 validation
      addSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:6432";
        proxyWebsockets = true;
      };
    };
  };

  system.stateVersion = "24.11";

}
