# Role module for promtail

{
  config,
  lib,
  ...
}:
let

  roleName = "promtail";

  lokiPort = 3100;

in
{

  options = {
    roles.${roleName}.enable = lib.mkEnableOption "enables ${roleName} role";
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    services.promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 28183;
          grpc_listen_port = 0;
          log_level = "warn";
        };
        positions.filename = "/tmp/positions.yaml";
        clients = [
          { url = "http://metrics:${toString lokiPort}/loki/api/v1/push"; }
          #        { url = "http://haskbike-ec2.${peers.networks.${peers.hosts.haskbike-ec2.network}.domain}:${toString lokiPort}/loki/api/v1/push"; name = "loki-bikes"; }
        ];
        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              max_age = "24h";
              labels = {
                job = "systemd-journal";
                host = "127.0.0.1";
              };
            };
            relabel_configs = [
              {
                source_labels = [ "__journal__systemd_unit" ];
                target_label = "unit";
              }
              {
                target_label = "host";
                replacement = "${config.networking.hostName}";
              }
            ];
          }
        ];
      };
    };

  };
}
