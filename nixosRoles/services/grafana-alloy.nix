# Role module for Grafana Alloy

{
  config,
  lib,
  ...
}:
let

  roleName = "grafana-alloy";

  lokiPort = 3100;

in
{

  options = {
    roles.${roleName}.enable = lib.mkEnableOption "enables ${roleName} role";
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    services.alloy = {
      enable = true;
    };

    environment.etc."alloy/journal.alloy".text = ''
      loki.source.journal "journal" {
        max_age       = "24h"
        forward_to    = [loki.write.default.receiver]

        labels = {
          job  = "systemd-journal",
          host = "127.0.0.1",
        }

        relabel_rules = loki.relabel.journal.rules
      }

      loki.relabel "journal" {
        forward_to = []

        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }

        rule {
          target_label = "host"
          replacement  = "${config.networking.hostName}"
        }
      }

      loki.write "default" {
        endpoint {
          url = "http://metrics:${toString lokiPort}/loki/api/v1/push"
        }
      }
    '';

  };
}
