{
  # Don't boot before /nix and /persist are mounted
  fileSystems."/nix".neededForBoot = true;
  fileSystems."/persist".neededForBoot = true;
  # Set nodev device at root directory to tmpfs
  disko.devices.nodev = {
    "/" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=25%" # Maximum amount of RAM root directory can take up
        "mode=755"
      ];
    };
  };
  # Define main device for persistent directories
  disko.devices.disk.main = {
    device = "/dev/sda";
    type = "disk";
    # Give disk a GPT partition table
    content.type = "gpt";
    # Boot and ESP partitions to reliably boot on modern hardware
    content.partitions.boot = {
      name = "boot";
      size = "1M";
      type = "EF02";
    };

    content.partitions.esp = {
      name = "ESP";
      size = "1G";
      type = "EF00";

      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
      };
    };

    content.partitions.swap = {
      size = "4G";

      content = {
        type = "swap";
        resumeDevice = true;
      };
    };
    # Root partition with BTRFS filesystem
    content.partitions.root = {
      name = "root";
      size = "100%";

      content = {
        type = "btrfs"; # Set filesystem as BTRFS
        extraArgs = [ "-f" ];
        # Define subvolumes
        subvolumes = {
          # Storage for files and directories to persist between reboots
          "/persist" = {
            mountOptions = [
              "subvol=persist"
              "noatime"
            ];
            mountpoint = "/persist";
          };
          # Nix store directory required for boot
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
}
