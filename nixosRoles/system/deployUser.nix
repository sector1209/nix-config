# custom module for user "deploy"

{
  pkgs,
  lib,
  config,
  secrets,
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

    # Create deploy group
    users.groups.deploy = { };

    # Create a dedicated user for deployment
    users.users.deploy = {
      # Disable home directory and default shell
      isSystemUser = true;
      shell = pkgs.bash;
      group = "deploy";
      # Disable password login
      hashedPassword = null;
      # Needed for SSH agent forwarding
      home = "/var/deploy";
      createHome = true;
      # Add your public SSH key here
      openssh.authorizedKeys.keys = [
        secrets.nixos-deploy-key-pub
      ];
    };

    # Disable passwordless sudo generally
    security.sudo.wheelNeedsPassword = lib.mkForce true;

    # Limit sudo access to commands needed for remote rebuilding
    security.sudo.extraRules =
      let
        storePrefix = "/nix/store/*";
        systemName = "nixos-system-${config.networking.hostName}-*";
        envVariants = [
          "/usr/bin/env"
          "env"
        ];
      in
      [
        {
          users = [ "deploy" ];
          runAs = "root";
          commands =
            (map (env: {
              command = ''/bin/sh -c exec ${env} -i PATH\="''${PATH-}" "$@" sh nix-env -p /nix/var/nix/profiles/system --set ${storePrefix}-${systemName}'';
            }) envVariants)
            ++ (map (env: {
              command = ''/bin/sh -c exec ${env} -i PATH\="''${PATH-}" LOCALE_ARCHIVE\="''${LOCALE_ARCHIVE-}" NIXOS_NO_CHECK\="''${NIXOS_NO_CHECK-}" NIXOS_INSTALL_BOOTLOADER\=[01] "$@" sh systemd-run -E LOCALE_ARCHIVE -E NIXOS_INSTALL_BOOTLOADER -E NIXOS_NO_CHECK --collect --no-ask-password --pipe --quiet --service-type\=exec --unit\=nixos-rebuild-switch-to-configuration ${storePrefix}-${systemName}/bin/switch-to-configuration *'';
            }) envVariants);
        }
      ];

    programs.ssh.startAgent = true;

    # Enable pam authentication with SSH keys
    security.pam = {
      sshAgentAuth = {
        enable = true;
        authorizedKeysFiles = [ "/etc/ssh/authorized_keys.d/%u" ];
      };
      # Let pam authenticate sudo via SSH keys
      services.sudo = {
        sshAgentAuth = true;
        logFailures = true;
      };
    };

    # Allow the deploy user to manage the system
    nix.settings.trusted-users = [
      "root"
      "deploy"
    ];

  };
}
