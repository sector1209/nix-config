{
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
  ];

  roles = {
    proxmoxContainer.enable = true;
    technitium-dns = {
      enable = true;
      hostName = "dns";
    };
  };

  system.stateVersion = "24.11";

}
