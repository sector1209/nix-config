# Role module for X

{
  lib,
  config,
  ...
}:
let

  roleName = "influxdb";

in
{

  options = {
    roles.${roleName}.enable = lib.mkEnableOption "enables ${roleName} role";
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    sops.secrets.influxdb-user-pass = {
      owner = "influxdb2";
    };

    services.influxdb2 = {
      enable = true;
      provision.users.dan.passwordFile = config.sops.secrets.influxdb-user-pass.path;
    };

    networking.firewall = {
      allowedUDPPorts = [
        8086
      ];
      allowedTCPPorts = [
        8086
      ];
    };

    services.nginx.virtualHosts."influxdb.danmail.me" = {
      addSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "http://localhost:8086";
      };
    };

  };
}
