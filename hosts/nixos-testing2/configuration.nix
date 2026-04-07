# configuration for nixos-testing

{
  ...
}:
let

  hostname = "nixos-testing2";

in
{

  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = hostname;

  roles = {

    proxmoxContainer.enable = true;

    deployMachine.enable = true;

  };

  system.stateVersion = "24.11";

}
