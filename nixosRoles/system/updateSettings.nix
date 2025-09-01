# custom module to for auto-update settings

{
  pkgs,
  lib,
  config,
  ...
}:
{

  options = {
    roles.updateSettings.enable = lib.mkEnableOption "enables update settings module";
  };

  config = lib.mkIf config.roles.updateSettings.enable {

    # Enable automatic updates (doesn't work for flakes)
    #    system.autoUpgrade = {
    #      enable = true;
    #      allowReboot = true;
    #      flake = "/etc/nixos.#${hostname}";
    #      flags = [ "--update-input" ];
    #    };

  };
}
