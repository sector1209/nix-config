{
  ...
}:
{
  # Other configurations omitted

  disko = {
    # Do not let Disko manage fileSystems.* config for NixOS.
    # Reason is that Disko mounts partitions by GPT partition names, which are
    # easily overwritten with tools like fdisk. When you fail to deploy a new
    # config in this case, the old config that comes with the disk image will
    # not boot either.
    enableConfig = false;

    devices = {
      # Define a disk
      disk.main = {
        # Size for generated disk image. 2GB is enough for me. Adjust per your need.
        imageSize = "10G";
        # Path to disk. When Disko generates disk images, it actually runs a QEMU
        # virtual machine and runs the installation steps. Whether your VPS
        # recognizes its hard disk as "sda" or "vda" doesn't matter. We abide to
        # Disko's QEMU VM and use "vda" here.
        device = "/dev/sda";
        type = "disk";
        # Parititon table for this disk
        content = {
          # Use GPT partition table. There seems to be some issues with MBR support
          # from Disko.
          type = "gpt";
          # Partition list
          partitions = {
            # Compared to MBR, GPT partition table doesn't reserve space for MBR
            # boot record. We need to reserve the first 1MB for MBR boot record,
            # so Grub can be installed here.
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
              # Use the highest priority to ensure it's at the beginning
              priority = 0;
            };

            # ESP partition, or "boot" partition as you may call it. In theory,
            # this config will support VPSes with both EFI and BIOS boot modes.
            ESP = {
              name = "ESP";
              # Reserve 512MB of space per my own need. If you use more/less
              # on your boot partition, adjust accordingly.
              size = "512M";
              type = "EF00";
              # Use the second highest priority so it's before the remaining space
              priority = 1;
              # Format as FAT32
              content = {
                type = "filesystem";
                format = "vfat";
                # Use as boot partition. Disko use the information here to mount
                # partitions on disk image generation. Use the same settings as
                # fileSystems.*
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };

            # Parition to store the NixOS system, use all remaining space.
            nix = {
              size = "100%";
              # Format as Btrfs. Change per your needs.
              content = {
                type = "filesystem";
                format = "btrfs";
                # Use as the Nix partition. Disko use the information here to mount
                # partitions on disk image generation. Use the same settings as
                # fileSystems.*
                mountpoint = "/nix";
                mountOptions = [
                  "compress-force=zstd"
                  "nosuid"
                  "nodev"
                ];
              };
            };
          };
        };
      };

      # Since I enabled Impermanence, I need to declare the root partition as tmpfs,
      # so Disko can mount the partitions when generating disk images
      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = [
          "relatime"
          "mode=755"
          "nosuid"
          "nodev"
        ];
      };
    };
  };

  # Since we aren't letting Disko manage fileSystems.*, we need to configure it ourselves
  # Root partition, is tmpfs because I enabled impermanence.
  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "relatime"
      "mode=755"
      "nosuid"
      "nodev"
    ];
  };

  # /nix partition, third partition on the disk image. Since my VPS recognizes
  # hard drive as "sda", I specify "sda3" here. If your VPS recognizes the drive
  # differently, change accordingly
  fileSystems."/nix" = {
    device = "/dev/sda3";
    fsType = "btrfs";
    options = [
      "compress-force=zstd"
      "nosuid"
      "nodev"
    ];
  };

  # /boot partition, second partition on the disk image. Since my VPS recognizes
  # hard drive as "sda", I specify "sda2" here. If your VPS recognizes the drive
  # differently, change accordingly
  fileSystems."/boot" = {
    device = "/dev/sda2";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # /persist partition, my custom partition on the disk image. Since my VPS recognizes
  # hard drive as "sda", I specify "sda3" here. If your VPS recognizes the drive
  # differently, change accordingly
  fileSystems."/persist" = {
    device = "/dev/sda3";
    fsType = "btrfs";
    options = [
      "compress-force=zstd"
      "nosuid"
      "nodev"
    ];
  };

}
