# Role module for X

{
  lib,
  config,
  self,
  ...
}:
let

  roleName = "grafanaStack";

  #  inherit (self.collective) peers;

  inherit (lib)
    filterAttrs
    mapAttrs
    attrValues
    flatten
    ;

  allHosts = self.nixosConfigurations;

  hostInTailnetF = k: v: v.config.services.tailscale.enable;
  tailnetHosts = filterAttrs hostInTailnetF allHosts;

  enabledExportersF =
    name: host:
    filterAttrs (
      k: v: (k != "unifi-poller" && k != "unpoller" && k != "minio" && k != "tor") && (v.enable or false)
    ) host.config.services.prometheus.exporters;
  enabledExporters = mapAttrs enabledExportersF tailnetHosts;

  mkScrapeConfigExporter = hostname: ename: ecfg: {
    job_name = "${hostname}-${ename}";
    static_configs = [ { targets = [ "${hostname}:${toString ecfg.port}" ]; } ];
    relabel_configs = [
      {
        target_label = "instance";
        replacement = "${hostname}";
      }
      {
        target_label = "job";
        replacement = "${ename}";
      }
    ];
  };

  mkScrapeConfigHost = name: exporters: mapAttrs (mkScrapeConfigExporter name) exporters;
  scrapeConfigsByHost = mapAttrs mkScrapeConfigHost enabledExporters;

  autogenScrapeConfigs = flatten (map attrValues (attrValues scrapeConfigsByHost));

  lokiPort = 3100;

in
{

  options = {
    roles.${roleName}.enable = lib.mkEnableOption "enables ${roleName} role";
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    services.grafana = {
      enable = true;
      settings.server = {
        # Listening address and TCP port
        http_addr = "0.0.0.0";
        http_port = 9010;
        # Grafana needs to know on which domain and URL it's running:
        domain = config.networking.hostName;
      };
      provision = {
        enable = true;
        # Set up the datasources
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://localhost:${toString config.services.prometheus.port}";
            isDefault = true;
          }
        ];
      };
    };

    services.prometheus = {
      # https://xeiaso.net/blog/prometheus-grafana-loki-nixos-2020-11-20
      enable = true;
      port = 9011;
      scrapeConfigs = autogenScrapeConfigs; # ++ [
      #      {
      #        job_name = "proxmox";
      #        static_configs = [
      #		 { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ]; }
      #            { targets = [ "workstation:${toString config.services.prometheus.exporters.smartctl.port}" ]; }
      #            { targets = [ "workstation:${toString config.services.prometheus.exporters.postgres.port}" ]; }
      #            { targets = [ "workstation:${toString config.services.prometheus.exporters.zfs.port}" ]; }
      #        ];
      #      }
      #    ];
    };

    services.loki = {
      enable = true;
      configuration = {
        auth_enabled = false;
        server = {
          http_listen_port = lokiPort;
          log_level = "warn";
        };
        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore.store = "inmemory";
              replication_factor = 1;
            };
            final_sleep = "0s";
          };
          chunk_idle_period = "5m";
          chunk_retain_period = "30s";
        };
        schema_config = {
          configs = [
            {
              from = "2022-05-06";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };
        compactor.working_directory = "/tmp/loki/compactor";
        storage_config = {
          tsdb_shipper = {
            cache_location = "/tmp/loki/cache";
            active_index_directory = "/tmp/loki/index";
          };
          boltdb.directory = "/tmp/loki/index";
          filesystem.directory = "/tmp/loki/chunks";
        };
        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
        };
        analytics = {
          reporting_enabled = false;
        };
      };
    };

    roles.nginx.enable = true;

    services.nginx.virtualHosts."grafana.danmail.me" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "http://localhost:9010";
      };
    };

  };
}
