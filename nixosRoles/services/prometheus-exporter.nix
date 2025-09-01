# Role module for X

{
  lib,
  config,
  ...
}:
let

  roleName = "prometheus-exporter";

in
{

  options = {
    roles.${roleName}.enable = lib.mkEnableOption "enables ${roleName} role";
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    services.prometheus = {
      # https://xeiaso.net/blog/prometheus-grafana-loki-nixos-2020-11-20
      enable = true;
      port = 9011;

      # Enable node exporter
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9012;
        };
        smartctl = {
          enable = config.services.smartd.enable;
          openFirewall = config.services.smartd.enable;
          # Defaults:
          user = "smartctl-exporter";
          group = "disk";
          port = 9633;
        };
      };
    };

  };
}
