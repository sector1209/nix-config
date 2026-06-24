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
  # Return an attribute set (sops configuration) for each item in the list hmSopsUsers
  mkSopsConfig = user: {
    "home-manager-sops-key-${user}" = {
      owner = "${user}";
      path = "/home/${user}/.config/sops/age/keys.txt";
    };
  };

  # Create a list of NixOS sops configs
  hmSopsConfigsList = lib.map mkSopsConfig hmSopsUsers;

  # Generate a sops.secret.* configuration for each user in hmUsers
  # Turn hmSopsConfigsList into an attribute set
  hmSecretsConfig = lib.mergeAttrsList hmSopsConfigsList;

in
{

  imports = [
    inputs.nix-secrets.nixosModules.nas
  ];

  options = {
    roles.sops.enable = lib.mkEnableOption "enables sops-nix module";
  };

  config = lib.mkIf config.roles.sops.enable {

    sops.secrets = lib.mkIf (
      (config ? home-manager) && (config.home-manager.users != { })
    ) hmSecretsConfig;

  };
}
