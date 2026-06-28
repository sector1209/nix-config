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
    roles.${roleName}.enable = lib.mkEnableOption "enables ${roleName} role";
  };

  config = lib.mkIf config.roles.${roleName}.enable {
    # Clean /tmp on boot as it is preserved
    boot.tmp.cleanOnBoot = true;
    # Prevent systemd-machine-id-commit.service error
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

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
          # Prevent /tmp from filling
          {
            directory = "/tmp";
            mode = "0777"; # Make /tmp world writeable
          }
          "/var/lib/tailscale" # Tailscale state
        ];
      };
    };

  };
}
