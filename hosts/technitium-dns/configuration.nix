# configuration for technitium-dns

{
  modulesPath,
  config,
  pkgs,
  ...
}:
let

  hostname = "technitium-dns";

in
{

  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = hostname;

  roles = {

    #  containerSettings.enable = true;

    proxmoxContainer.enable = true;

    technitium-dns = {
      enable = true;
      hostName = "dns";
    };

    services.beszel-agent.enable = true;

  };

  system.stateVersion = "24.11";

}
