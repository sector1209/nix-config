{ ... }:
let

  hostname = "impermanence-testing";

in
{

  imports = [
    ./hardware-configuration.nix
    ./preservation.nix
  ];

  networking.hostName = hostname;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.qemuGuest.enable = true;

  system.stateVersion = "26.05";
}
