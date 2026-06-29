# custom module for sops

{
  lib,
  config,
  inputs,
  ...
}:
let

  # List users with a home-manager config
  # Take just the names of each attribute set in config.home-manager.users
  hmUsers = builtins.attrNames config.home-manager.users;

  # Of those with a home-manager config, list those with home-manager sops enabled
  # Filter home-manager users for whom config.home-manager.<user>.sops exists
  hmSopsUsers = lib.filter (user: config.home-manager.users.${user} ? sops) hmUsers;

  # Create a NixOS-sops config for each home-manager user with home-manager sops enabled
  # Return an attribute set (sops configuration)
  mkSopsConfig = user: {
    "home-manager-sops-key-${user}" = {
      owner = "${user}";
      path = "/home/${user}/.config/sops/age/keys.txt";
    };
  };

  # Create a list of NixOS sops configs attribute sets
  hmSopsConfigsList = lib.map mkSopsConfig hmSopsUsers;

  # Generate a sops.secret.* configuration for each user in hmSopsUsers
  # Turn hmSopsConfigsList into an attribute set
  hmSecretsConfig = lib.mergeAttrsList hmSopsConfigsList;

  # List the groups of all home-manager sops users
  # Apply the function to each item in hmSopsUsers to create a new list
  hmSopsUserGroups = lib.map (user: config.users.users.${user}.group) hmSopsUsers;

  # Create a systemd tmpfiles rules config for each home-manager user with home-manager sops enabled
  # Return a string (systemd tmpfiles config)
  mkTmpfilesConfig =
    user: group: "Z ${config.users.users.${user}.home}/.config 0755 ${user} ${group} - -";

  # Create a list of Nixos Systemd tmpfiles rules configs
  # Combine the lists hmSopsUsers and hmSopsUserGroups via the function mkTmpfilesConfig
  tmpfilesConfig = lib.zipListsWith mkTmpfilesConfig hmSopsUsers hmSopsUserGroups;

in
{

  imports = [
    inputs.nix-secrets.nixosModules.nas
  ];

  options = {
    roles.sops.enable = lib.mkEnableOption "enables sops-nix module";
  };

  config = lib.mkIf config.roles.sops.enable {

    # Install home-manager sops secret if needed
    sops = {
      secrets = lib.mkIf (hmSopsUsers != [ ]) hmSecretsConfig;
      useSystemdActivation = config.preservation.enable;
    };

    # Ensure the home .config directory has correct ownership
    systemd.tmpfiles.rules = lib.mkIf (hmSopsUsers != [ ]) tmpfilesConfig;

    # Make sure Sops runs after systemd tmpfiles have been set up
    systemd.services.sops-install-secrets =
      lib.mkIf (config.preservation.enable && (hmSopsUsers != [ ]))
        {
          before = [ "systemd-tmpfiles-resetup.service" ];
          requires = [ "systemd-tmpfiles-resetup.service" ];
        };

  };
}
