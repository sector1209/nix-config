# configuration for edgeware

{
  config,
  lib,
  ...
}:
let

  hostname = "edgeware";

in
{

  imports = [
    ./hardware-configuration.nix
    ./haproxy.nix
  ];

  networking.hostName = hostname;

  roles.preservation = {
    enable = true;
    rootFs = "tmpfs";
  };

  services.tailscale = {
    useRoutingFeatures = "server";
    extraSetFlags = [ "--advertise-exit-node" ];
  };

  # Disable passwordless sudo.
  security.sudo.wheelNeedsPassword = true;

  system.stateVersion = "24.11";

  # From https://lantian.pub/en/article/modify-computer/nixos-low-ram-vps.lantian/

  boot.kernelParams = [
    # Disable auditing
    "audit=0"
    # Do not generate NIC names based on PCIe addresses (e.g. enp1s0, useless for VPS)
    # Generate names based on orders (e.g. eth0)
    "net.ifnames=0"
  ];

  # My Initrd config, enable ZSTD compression and use systemd-based stage 1 boot
  boot.initrd = {
    compressor = "zstd";
    compressorArgs = [
      "-19"
      "-T0"
    ];
    systemd.enable = true;
  };

  # Install Grub
  boot.loader.grub = {
    enable = !config.boot.isContainer;
    default = "saved";
    devices = [ "/dev/sda" ];
  };

  # Manage networking with systemd-networkd
  systemd.network.enable = true;
  networking.useNetworkd = true;
  #  services.resolved.enable = false;

  # Kernel modules required by QEMU (KVM) virtual machine
  boot.initrd.postDeviceCommands = lib.mkIf (!config.boot.initrd.systemd.enable) ''
    # Set the system time from the hardware clock to work around a
    # bug in qemu-kvm > 1.5.2 (where the VM clock is initialised
    # to the *boot time* of the host).
    hwclock -s
  '';

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

  preservation.preserveAt."/persist" = {
    directories = [
      "/var/lib/systemd/coredump"
    ];
  };

  programs.fuse.userAllowOther = true;

}
