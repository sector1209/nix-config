# custom module for gotify

{
  pkgs,
  lib,
  config,
  modulesPath,
  inputs,
  outputs,
  ...
}:
{

  options = {
    roles.gotify.enable = lib.mkEnableOption "enables gotify module";
  };

  config = lib.mkIf config.roles.gotify.enable {

    # enable nginx module
    roles.nginx.enable = true;

    # enable gotify service
    services.gotify = {
      enable = true;
      #      port = 2999;
      environment = {
        GOTIFY_SERVER_PORT = 2999;
      };
    };

    # configure nginx host
    services.nginx.virtualHosts = {
      "gotify.danmail.me" = {
        enableACME = true;
        acmeRoot = null; # i think this makes it use DNS-01 validation
        addSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:2999";
          proxyWebsockets = true;
        };
      };
    };

  };

}
