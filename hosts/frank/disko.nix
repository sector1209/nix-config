{
  ...
}:
{
  disko.devices = {
    disk = {
      main = {
        # Main SSD with impermanent root
        device = "/dev/sda";
        type = "disk";
        # imageSize = "10G";
        content = {
          type = "gpt";
          partitions = {
            # Provision boot partition for Systemd-boot bootloader
            boot = {
              name = "boot";
              size = "1M";
              type = "EF02";
            };
            # Provision EFI partition for Systemd-boot kernel and initramfs
            esp = {
              name = "ESP";
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            # Provision swap partition
            swap = {
              size = "16G";
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
            # Provision impermanent root partition
            root = {
              name = "root";
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "root_vg";
              };
            };
          };
        };
      };
      # Provision secondary data disk
      secondary = {
        # Identify device
        device = "/dev/sdb";
        type = "disk";
        content = {
          # Set partition table to GPT
          type = "gpt";
          # Provision partitions
          partitions = {
            # Provision data partition
            data = {
              name = "data";
              size = "100%";
              # Provision content on data partition
              content = {
                # Provision BTRFS filesystem
                type = "btrfs";
                # Provision subvolumes on BTRFS filesystem
                subvolumes = {
                  "/dataRoot" = {
                    mountpoint = "/mnt/dataRoot";
                  };
                };
              };
            };
          };
        };
      };
    };
    # Provision volume group for impermanent root on /dev/sda
    lvm_vg = {
      root_vg = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];

              subvolumes = {
                "/root" = {
                  mountpoint = "/";
                };

                "/persist" = {
                  mountOptions = [
                    "subvol=persist"
                    "noatime"
                  ];
                  mountpoint = "/persist";
                };

                "/nix" = {
                  mountOptions = [
                    "subvol=nix"
                    "noatime"
                  ];
                  mountpoint = "/nix";
                };
              };
            };
          };
        };
      };
    };
  };
}
