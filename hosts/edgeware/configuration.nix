# configuration for edgeware

{
  modulesPath,
  config,
  pkgs,
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

  # From my imperm module

  fileSystems."/persist".neededForBoot = true;
  environment.persistence."/persist/system" = {
    hideMounts = true;
    directories = [
      #      "/etc/nixos"
      "/var/log"
      #      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
      "/var/lib/tailscale"
      #      { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      #      { file = "/var/keys/secret_file"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
      {
        file = "/sops-keys/sops/age/keys.txt";
        parentDirectory = {
          mode = "u=rwx,g=,o=";
        };
      }
    ];
  };

  programs.fuse.userAllowOther = true;

  roles.services.beszel-agent.enable = true;

}
