# custom module for user "deploy"

{
  pkgs,
  lib,
  config,
  ...
}:
let

  configName = "deployUser";

in
{

  options = {
    roles.${configName}.enable = lib.mkEnableOption "enables ${configName} role";
  };

  config = lib.mkIf config.roles.${configName}.enable {

    sops.secrets = {
      "keys/nixos-deploy-key" = { };
      "keys/nixos-deploy-key-pub" = { };
    };

    # Create deploy group
    users.groups.deploy = { };

    # Create a dedicated user for deployment
    users.users.deploy = {
      # Disable home directory and default shell
      isSystemUser = true;
      shell = pkgs.bash;
      group = "deploy";
      # Add to wheel group for sudo access
      extraGroups = [ "wheel" ];
      # Disable password login
      hashedPassword = null;
      # Add your public SSH key here
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE75I9p0QcSrZT6nJ1kZ+R+OvRQyyUr09xqsMbo8y7zF dan@nixos-testing"
      ];
    };

    # Disable passwordless sudo generally
    security.sudo.wheelNeedsPassword = lib.mkForce true;

    # Allow sudo access without password for the deploy user
    security.sudo.extraRules = [
      {
        users = [ "deploy" ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
    #    security.sudo.extraRules = [{
    #      users = [ "deploy" ];
    #      commands = [{
    #	command = "ALL";
    # Attempt to limit passwordless sudo permissions to rebuild commands
    #	command = "/run/current-system/sw/bin/systemd-run";
    #	command = "/run/current-system/sw/bin/nixos-rebuild";
    #	options = [ "NOPASSWD" ];
    #      }];
    #      commands = [
    #        {
    #          command = "/nix/store/*/bin/switch-to-configuration";
    #          options = [ "NOPASSWD" ];
    #        }
    #        {
    #          command = "/run/current-system/sw/bin/nix-store";
    #          options = [ "NOPASSWD" ];
    #        }
    #        {
    #          command = "/run/current-system/sw/bin/nix-env";
    #          options = [ "NOPASSWD" ];
    #        }
    #        {
    #          command = ''/bin/sh -c "readlink -e /nix/var/nix/profiles/system || readlink -e /run/current-system"'';
    #          options = [ "NOPASSWD" ];
    #        }
    #        {
    #          command = "/run/current-system/sw/bin/nix-collect-garbage";
    #          options = [ "NOPASSWD" ];
    #        }
    #	{
    #	  command = "/run/current-system/sw/bin/nixos-rebuild";
    #	  options = [ "NOPASSWD" ];
    #	}
    #      ];
    #    }];

    programs.ssh.startAgent = true;

    # Enable PAM authentication with SSH keys
    security.pam = {
      services.sudo = {
        sshAgentAuth = true;
        logFailures = true;
      };
      sshAgentAuth = {
        enable = true;
        authorizedKeysFiles = [ "/etc/ssh/authorized_keys.d/%u" ];
      };
    };

    # Allow the deploy user to manage the system
    nix.settings.trusted-users = [
      "root"
      "deploy"
    ];

  };
}
