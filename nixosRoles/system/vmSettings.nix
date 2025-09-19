{
  config,
  modulesPath,
  lib,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  options = {
    roles.vmSettings.enable = lib.mkEnableOption "enables vm settings module";
  };

  config = lib.mkIf config.roles.vmSettings.enable {
    #Provide a default hostname
    networking.hostName = lib.mkDefault "base";

    # Enable QEMU Guest for Proxmox
    services.qemuGuest.enable = lib.mkDefault true;

    # Use the boot drive for grub
    boot.loader.grub.enable = lib.mkOverride 1250 true;
    boot.loader.grub.devices = lib.mkDefault [ "nodev" ];

    boot.growPartition = lib.mkDefault true;

    # Allow remote updates with flakes and non-root users
    nix.settings.trusted-users = [
      "root"
      "@wheel"
    ];

    programs.ssh.startAgent = true;

    # Default filesystem
    fileSystems."/" = lib.mkDefault {
      device = "/dev/disk/by-label/nixos";
      autoResize = true;
      fsType = lib.mkDefault "ext4";
    };

  };
}
