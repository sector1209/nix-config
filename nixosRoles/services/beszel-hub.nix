# Role module for Beszel hub

{
  lib,
  config,
  ...
}:
let

  roleName = "beszel-hub";

in
{

  options = {
    roles.${roleName}.enable = lib.mkEnableOption "enables ${roleName} role";
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    roles.nginx.enable = true;

    # Configure nginx host
    services.nginx.virtualHosts = {
      "beszel.danmail.me" = {
        enableACME = true;
        acmeRoot = null; # i think this makes it use DNS-01 validation
        addSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:8090";
          proxyWebsockets = true;
        };
      };
    };

    services.beszel.hub = {
      enable = true;
      environment = {
        APP_URL = "https://beszel.danmail.me";
      };
    };
  };
}
