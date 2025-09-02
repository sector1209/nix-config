# nginx custom module

{
  lib,
  config,
  ...
}:
{

  options = {
    roles.nginx.enable = lib.mkEnableOption "enables nginx module";
  };

  config = lib.mkIf config.roles.nginx.enable {

    roles.acme.enable = true;

    security.acme.defaults.reloadServices = [ "nginx.service" ];

    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [
        80
        443
      ];
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };
  };

}
