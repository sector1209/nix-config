# configuration for charlie

{
  ...
}:
let

  hostname = "charlie";

in
{

  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = hostname;

  ### Enable roles

  roles = {

    proxmoxContainer = {
      enable = true;
      privilaged = true;
    };

    jellyfin.enable = true;

    nextcloud.enable = true;

    immich.enable = true;

    nginx.enable = true;

    beszel-agent.extraFilesystems = [
      "/var/lib/nextcloud__Nextcloud Mount"
    ];

  };

  system.stateVersion = "24.11";

}
