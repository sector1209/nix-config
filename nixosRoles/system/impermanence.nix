# custom module for nixos impermanence for a btrfs formatted system

{
  lib,
  config,
  inputs,
  ...
}:
{

  imports = [
    inputs.impermanence.nixosModules.default
  ];

  options = {
    roles.imperm.enable = lib.mkEnableOption "enables impermanence module";
  };

  config = lib.mkIf config.roles.imperm.enable {

    boot.loader.systemd-boot.enable = lib.mkForce true;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.initrd.postDeviceCommands = lib.mkAfter ''
            mkdir /btrfs_tmp
            mount /dev/root_vg/root /btrfs_tmp
            if [[ -e /btrfs_tmp/root ]]; then
      	mkdir -p /btrfs_tmp/old_roots
      	timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
      	mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
            fi

            delete_subvolume_recursively() {
      	IFS=$'\n'
      	for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
      	  delete_subvolume_recursively "/btrfs_tmp/$i"
      	done
      	btrfs subvolume delete "$1"
            }

            # Keep the newest, delete all others
            keep=$(ls -1t /btrfs_tmp/old_roots | head -n1)
            for i in /btrfs_tmp/old_roots/*; do
      	if [[ "$(basename "$i")" != "$keep" ]]; then
      	  delete_subvolume_recursively "$i"
      	fi
            done

            btrfs subvolume create /btrfs_tmp/root
            umount /btrfs_tmp
    '';

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

  };
}
