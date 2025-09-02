# configuration for dennis

{
  ...
}:
let

  hostname = "dennis";
  user = "dan";

in
{

  imports = [
    ./hardware-configuration.nix
    ./transfer.nix
  ];

  networking.hostName = hostname;

  roles = {

    docker.enable = true;

    vmSettings.enable = true;

    glances.enable = true;

    services.beszel-agent.enable = true;

  };

  # Define a user account.
  users.users.${user} = {
    uid = 1001;
    extraGroups = [
      "wheel"
      "docker"
      "systemd-journal"
    ];
  };

  # Enable automatic updates
  system.autoUpgrade = {
    flake = "/etc/nixos.#${hostname}";
  };

  # Don't use the boot drive for grub
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  #  boot.loader.grub.efiSupport = true;

  # Disks

  fileSystems."/mnt/diskyMedia" = {
    device = "/dev/disk/by-uuid/e02f9614-603e-4736-90e9-038403c13340";
    fsType = "ext4";
  };

  system.stateVersion = "23.11";
}
