# custom module for user configuration

{
  pkgs,
  lib,
  config,
  ...
}:
{

  options = {
    roles.zsh.enable = lib.mkEnableOption "enables zsh module";
  };

  config = lib.mkIf config.roles.zsh.enable {

    users.defaultUserShell = pkgs.zsh;
    environment.shells = [ pkgs.zsh ];

    programs = {
      zsh.enable = true;
      nix-ld.enable = true;
    };

    users.users.dan.shell = pkgs.zsh;

  };
}
