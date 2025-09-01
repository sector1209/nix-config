# custom module for networking

{
  pkgs,
  lib,
  config,
  ...
}:
{

  options = {
    roles.networking.enable = lib.mkEnableOption "enables networking module";
  };

  config = lib.mkIf config.roles.networking.enable {

    # disable ipv6
    networking.enableIPv6 = false;

    networking.hostName = lib.mkDefault "defaultHostname";

  };
}
