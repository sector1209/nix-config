# modules for glances service

{
  pkgs,
  lib,
  config,
  ...
}:
{

  options = {
    roles.glances.enable = lib.mkEnableOption "enables glances module";
  };

  config = lib.mkIf config.roles.glances.enable {

    services.glances = {
      enable = true;
      openFirewall = true;
      extraArgs = [
        "--webserver"
      ];
    };

  };

}
