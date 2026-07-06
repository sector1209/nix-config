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
      # Add to wheel group for sudo access
      extraGroups = [ "wheel" ];
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
