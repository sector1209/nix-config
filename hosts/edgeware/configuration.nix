{
  config,
  secrets,
  ...
}:
let

  hostname = "edgeware";

in
{

  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = hostname;

  roles = {
    preservation = {
      enable = true;
      rootFs = "tmpfs";
    };
    edgeProxy = {
      enable = true;
      virtualHosts = {
        "cal.${secrets.domainName}" = {
          destination = "mac:443";
          useUpstream = true;
        };
        "blog.${secrets.domainName}" = {
          destination = "mac:443";
          useUpstream = true;
        };
      };
    };
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

  # My Initrd config, enable ZSTD compression
  boot.initrd = {
    compressor = "zstd";
    compressorArgs = [
      "-19"
      "-T0"
    ];
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

  programs.fuse.userAllowOther = true;

}
