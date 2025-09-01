# custom module for global alias configuration

{
  pkgs,
  lib,
  config,
  ...
}:
{

  options = {
    roles.aliases.enable = lib.mkEnableOption "enables alias module";
  };

  config = lib.mkIf config.roles.aliases.enable {

    environment.shellAliases = {
      l = "ls -lah";
      cdnixdir = "cd /nixos-configs";
    };

  };
}
