# configuration for nginx

{
  modulesPath,
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let

  hostname = "generic-vm";

in
{

  imports = [
    ./hardware-configuration.nix
    #    "${modulesPath}/virtualisation/proxmox-image.nix"
    inputs.nixos-generators.nixosModules.all-formats
  ];

  networking.hostName = hostname;

  roles.vmSettings.enable = true;

  virtualisation.diskSize = 15 * 1024;

  proxmox.cloudInit.enable = true;

  # Nixos-generators options I think
  proxmox.qemuConf = {
    name = hostname;
    cores = 2;
    memory = 2048;
    additionalSpace = "20480";
    #    partitionTableType = "hybrid";
  };

  proxmox.qemuExtraConf = {
    machine = "q35";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE75I9p0QcSrZT6nJ1kZ+R+OvRQyyUr09xqsMbo8y7zF dan@nixos-testing"
  ];

  system.stateVersion = "25.05";

}
