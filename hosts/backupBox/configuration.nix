# configuration for charlie

{
  ...
}:
let

  hostname = "backupBox";

in
{

  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = hostname;

  ### Enable roles

  roles = {

    #  containerSettings.enable = true;

    proxmoxContainer = {
      enable = true;
      privilaged = true;
    };

    borgbackupServer.enable = true;

    services.beszel-agent.enable = true;

  };

  system.stateVersion = "24.11";

}
