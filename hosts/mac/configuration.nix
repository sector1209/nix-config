{
  secrets,
  ...
}:
let
  hostname = "mac";
in
{

  imports = [
    ./hardware-configuration.nix
    ./podman-compose.nix
    ./blog.nix
    ./logging.nix
  ];

  networking.hostName = hostname;

  roles = {
    preservation = {
      enable = true;
      rootFs = "btrfs-rollback";
    };
  };

  # Enable QEMU Guest for Proxmox
  services.qemuGuest.enable = true;

  # Disable passwordless sudo
  security.sudo.wheelNeedsPassword = true;

  users = {
    users.dan = {
      initialHashedPassword = secrets.mac-initialHashedPassword;
    };
  };

  system.stateVersion = "25.05";

  # From https://lantian.pub/en/article/modify-computer/nixos-low-ram-vps.lantian/

  boot.kernelParams = [
    # Disable auditing
    "audit=0"
    # Do not generate NIC names based on PCIe addresses (e.g. enp1s0, useless for VPS)
    # Generate names based on orders (e.g. eth0)
    "net.ifnames=0"
  ];

  # Manage networking with systemd-networkd
  systemd.network.enable = true;
  networking.useNetworkd = true;

  boot.initrd.availableKernelModules = [
    "virtio_net"
    "virtio_pci"
    "virtio_mmio"
    "virtio_blk"
    "virtio_scsi"
  ];
  boot.initrd.kernelModules = [
    "virtio_balloon"
    "virtio_console"
    "virtio_rng"
  ];

}
