{
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
  ];

  roles = {
    proxmoxContainer.enable = true;
    deployMachine.enable = true;
  };

  system.stateVersion = "24.11";

}
