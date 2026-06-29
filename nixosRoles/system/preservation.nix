# Role module for Preservation

{
  lib,
  config,
  inputs,
  ...
}:
let

  roleName = "preservation";

in
{

  imports = [
    inputs.preservation.nixosModules.default
  ];

  options = {
    roles.${roleName} = {
      enable = lib.mkEnableOption "enables ${roleName} role";
      rootFs = lib.mkOption {
        default = "";
        type = lib.types.enum [
          "tmpfs"
          "btrfs-rollback"
        ];
      };
    };
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    preservation = {
      enable = true;
      # Declare directories to be preserved
      preserveAt."/persist" = {
        files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }
          {
            file = "/etc/ssh/ssh_host_ed25519_key";
            how = "symlink";
            configureParent = true;
          }
          {
            file = "/etc/ssh/ssh_host_rsa_key";
            how = "symlink";
            configureParent = true;
          }
          # Preserve sops keys
          {
            file = "/sops-keys/sops/age/keys.txt";
            # inInitrd = true;
            mode = "600";
            configureParent = true;
            parent = {
              mode = "700";
            };
          }
        ];

        directories = [
          "/var/lib/systemd/timers"
          "/var/lib/nixos"
          "/var/log"
          "/var/lib/systemd/coredump"
          "/var/lib/tailscale" # Tailscale state
        ]
        ++ lib.optionals (config.roles.preservation.rootFs == "tmpfs") [
          # Prevent /tmp from filling
          {
            directory = "/tmp";
            mode = "0777"; # Make /tmp world writeable
          }
        ];
      };
    };

    fileSystems."/persist".neededForBoot = true;

    # Prevent systemd-machine-id-commit.service error
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

    programs.fuse.userAllowOther = lib.mkIf (config.roles.preservation.rootFs == "btrfs-rollback") true;

    # BTRFS rollback
    boot = lib.mkIf (config.roles.preservation.rootFs == "btrfs-rollback") {
      # Clean /tmp on boot as it is preserved
      tmp.cleanOnBoot = true;
      loader.systemd-boot.enable = lib.mkForce true;
      loader.efi.canTouchEfiVariables = true;
      initrd.systemd.enable = true;
      initrd.systemd.services.rollback = {
        description = "Btrfs root rollback to fresh subvolume";

        wantedBy = [ "initrd.target" ];
        after = [ "dev-root_vg-root.device" ];
        before = [ "sysroot.mount" ];

        unitConfig.DefaultDependencies = "no";

        serviceConfig.Type = "oneshot";
        script = ''
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

          # Keep the newest old_root, delete all others
          keep=$(ls -1t /btrfs_tmp/old_roots 2>/dev/null | head -n1)
          for i in /btrfs_tmp/old_roots/*; do
            [[ -e "$i" ]] || continue   # handle empty glob
            if [[ "$(basename "$i")" != "$keep" ]]; then
              delete_subvolume_recursively "$i"
            fi
          done

          btrfs subvolume create /btrfs_tmp/root
          umount /btrfs_tmp
        '';
      };
    };

  };

}
