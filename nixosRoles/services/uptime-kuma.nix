# Role module for X

{
  lib,
  config,
  ...
}:
let

  roleName = "uptime-kuma";

in
{

  options = {
    roles.${roleName}.enable = lib.mkEnableOption "enables ${roleName} role";
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    roles.nginx.enable = true;

    services.uptime-kuma.enable = true;

    services.nginx.virtualHosts = {
      "uptime.danmail.me" = {
        enableACME = true;
        acmeRoot = null; # i think this makes it use DNS-01
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:3001";
        };
      };
    };

  };
}
