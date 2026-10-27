{ ... }:
{

  imports = [
    ./hardware-configuration.nix
  ];

  roles = {
    preservation = {
      enable = true;
      rootFs = "tmpfs";
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.qemuGuest.enable = true;

  system.stateVersion = "26.05";

}
