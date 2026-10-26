{
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
    proxmoxContainer.enable = true;
    technitium-dns = {
      enable = true;
      hostName = "dns";
    };
  };

  system.stateVersion = "24.11";

}
