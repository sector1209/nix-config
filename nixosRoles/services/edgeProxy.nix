# Role module for edge proxy

{
  lib,
  config,
  pkgs,
  inputs,
  self,
  secrets,
  ...
}:
let

  roleName = "edgeProxy";

  # Get all hosts from flake
  allHosts = self.nixosConfigurations;

  # Filter for hosts with virtualHosts defined
  hostsWithVHostsF = n: v: v.config.roles.${roleName}.virtualHosts != { };
  hostsWithVHosts = lib.filterAttrs hostsWithVHostsF allHosts;

  # Filter for only virtualHosts attrset
  enabledVHostsF =
    name: host: lib.filterAttrs (n: v: (n != "")) host.config.roles.${roleName}.virtualHosts;
  virtualHosts = lib.concatMapAttrs enabledVHostsF hostsWithVHosts;

  # Duplicate detection
  # Flatten to a list of { host, name } for every virtualHost defined on every host
  hostVHostNamePairs = lib.concatMap (
    host:
    builtins.map (name: {
      inherit host name;
    }) (builtins.attrNames hostsWithVHosts.${host}.config.roles.${roleName}.virtualHosts)
  ) (builtins.attrNames hostsWithVHosts);

  # Group into { name = [ host1 host2 ... ]; }
  vHostNameToHosts = lib.foldl' (
    acc: pair: acc // { ${pair.name} = (acc.${pair.name} or [ ]) ++ [ pair.host ]; }
  ) { } hostVHostNamePairs;

  # Keep only names claimed by more than one host
  duplicateVHosts = lib.filterAttrs (name: hosts: builtins.length hosts > 1) vHostNameToHosts;

  # Make a list pairing virtualHost to destination
  mapList = lib.mapAttrsToList (
    name: value:
    "${name}  ${
      if value.useUpstream then
        (lib.concatStringsSep "_" [
          (lib.concatStrings (lib.strings.splitString ":" value.destination))
          "upstream"
        ])
      else
        (value.destination)
    };"
  ) virtualHosts;

  # Make the map of SRI destination to backend
  mkMap = lib.concatLines [
    "map $ssl_preread_server_name $https_backend {"
    (lib.trim (lib.concatLines mapList))
    "}"
  ];

  # Filter for hosts with useUpstream
  upstreamHostsF = n: v: v.useUpstream;
  upstreamHosts = lib.filterAttrs upstreamHostsF virtualHosts;

  # Create an upstream block for each filtered virtualHost
  upstreamBlocks = lib.mapAttrsToList (
    name: value:
    (lib.concatLines (
      let
        splitDestination = lib.concatStrings (lib.strings.splitString ":" value.destination);
      in
      [
        "upstream ${splitDestination}_upstream {"
        "  server ${value.destination};"
        "}"
      ]
    ))
  ) upstreamHosts;

  # Make the upstream blocks
  mkUpstreamBlocks = lib.concatLines (lib.lists.unique upstreamBlocks);

in
{

  options = {
    roles.${roleName} = {
      enable = lib.mkEnableOption "enables ${roleName} role";
      virtualHosts = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            { ... }:
            {
              options = {
                destination = lib.mkOption {
                  type = lib.types.str;
                  description = ''
                    Backend target the connection is proxied to. Include the port.
                  '';
                  example = "host:1234";
                };
                useUpstream = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = ''
                    Proxy to the upstream server instead of the destination.
                  '';
                };
              };
            }
          )
        );
      };
    };
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    assertions = lib.mapAttrsToList (name: hosts: {
      assertion = false;
      message = ''
        roles.edgeProxy.virtualHosts."${name}" is defined on multiple hosts: ${lib.concatStringsSep ", " hosts}.
        Only one definition can be active; destinations would otherwise be silently merged with one host's value overwriting the other's.
      '';
    }) duplicateVHosts;

    networking.firewall.allowedTCPPorts = [
      80
      443
      25565
      25566
      514
    ];

    services.nginx = {
      enable = true;

      streamConfig = ''
        # How long to wait for a ClientHello before giving up.
        preread_timeout 5s;

        #---------------------------------------------------------------------
        # HTTPS / SNI-based routing
        #---------------------------------------------------------------------

        ${mkMap}

        ${mkUpstreamBlocks}

        server {
          listen 443;
          listen [::]:443;

          proxy_pass $https_backend;
          ssl_preread on;

          # Sends PROXY protocol v1 to the backend.
          proxy_protocol on;

          proxy_connect_timeout 5s;
          proxy_timeout 10s;
        }
      '';
    };

    # Syslogd service for writing HAProxy logs to file
    services.rsyslogd = {
      enable = true;
      extraConfig = ''
        #################
        #### MODULES ####
        #################

        # provides TCP syslog reception
        module(load="imtcp")
        input(type="imtcp" port="514")

        template(name="rawmsg" type="string" string="%msg%\n")

        # Separate Caddy logs by tag
        if $programname == 'caddy-cal' then {
          action(type="omfile" file="/var/log/remote/caddy-cal.log" template="rawmsg")
          stop
        }
        if $programname == 'caddy-blog' then {
          action(type="omfile" file="/var/log/remote/caddy-blog.log" template="rawmsg")
          stop
        }
      '';
    };

    # Rotate rsyslogd files
    services.logrotate.settings."/var/log/remote/*.log" = {
      frequency = "daily";
      maxsize = "200M";
      rotate = 7;
      compress = true;
      delaycompress = true;
      missingok = true;
      notifempty = true;
      postrotate = "systemctl kill -s HUP syslog.service";
    };

    preservation.preserveAt."/persist" = {
      directories = [
        {
          directory = "/var/lib/private/crowdsec";
          mode = "0700";
        }
        {
          directory = "/var/lib/private/crowdsec-firewall-bouncer-register";
          mode = "0700";
        }
        "/var/lib/fail2ban"
      ];
    };

    systemd.tmpfiles.settings."10-crowdsec" = {
      "/var/lib/crowdsec/state" = lib.mkForce { };
      "/var/lib/crowdsec/state/hub/" = lib.mkForce { };
    };

    environment.etc = {
      "crowdsec/config.yaml".source =
        (pkgs.formats.yaml { }).generate "crowdsec.yaml"
          config.services.crowdsec.settings.general;

      "crowdsec/plugins/notification-http" = {
        source = "${config.services.crowdsec.package}/bin/notification-http";
        user = config.services.crowdsec.user;
        group = config.services.crowdsec.group;
        mode = "0500";
      };
    };

    systemd.services.crowdsec.serviceConfig = {
      # allow crowdsec to start its plugin process under plugin_config's user/group
      AmbientCapabilities = [
        "CAP_SETUID"
        "CAP_SETGID"
      ];
      CapabilityBoundingSet = [
        "CAP_SETUID"
        "CAP_SETGID"
      ]; # appended to the module's CAP_SYSLOG entries

      # your current filter from `systemctl cat`, minus ~@privileged
      SystemCallFilter = lib.mkForce [
        "~@reboot"
        "~@swap"
        "~@obsolete"
        "~@mount"
        "~@module"
        "~@debug"
        "~@cpu-emulation"
        "~@clock"
        "~@raw-io"
        "~@resources"
      ];
    };

    services.crowdsec.package =
      inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.crowdsec;

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "cscli-root" ''
        export PATH="$PATH:${pkgs.crowdsec}/bin"
        exec ${lib.getExe' pkgs.crowdsec "cscli"} -c /etc/crowdsec/config.yaml "$@"
      '')
    ];

    # Configure crowdsec
    services.crowdsec = {
      enable = true;

      #   autoUpdateService = true;

      hub.collections = [
        "crowdsecurity/linux"
        "crowdsecurity/sshd"
        "crowdsecurity/caddy"
      ];

      localConfig = {
        acquisitions = [
          {
            source = "file";
            filenames = [ "/var/log/remote/caddy-cal.log" ];
            log_level = "info";
            labels = {
              type = "caddy";
            };
          }
          {
            source = "file";
            filenames = [ "/var/log/remote/caddy-blog.log" ];
            log_level = "info";
            labels = {
              type = "caddy";
            };
          }
          # {
          #   source = "journalctl";
          #   journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
          #   labels.type = "syslog";
          # }
        ];

        parsers.s02Enrich =
          let
            entries = secrets.ip-whitelist;
            isCidr = lib.hasInfix "/";
          in
          [
            {
              name = "local/trusted-networks";
              description = "Trusted public IPs and internal networks";
              whitelist = {
                reason = "Trusted network";
                ip = lib.filter (e: !isCidr e) entries;
                cidr = lib.filter isCidr entries;
              };
            }
          ];

        notifications = [
          {
            type = "http";
            name = "http_default";
            log_level = "debug";
            format = ''
              {{- range $Alert := . -}}
                {{- $traefikRouters := GetMeta . "traefik_router_name" -}}
                {{- range .Decisions -}}
                {"metric":{"__name__":"cs_lapi_decision","instance":"${config.networking.hostName}","country":"{{$Alert.Source.Cn}}","asname":"{{$Alert.Source.AsName}}","asnumber":"{{$Alert.Source.AsNumber}}","latitude":"{{$Alert.Source.Latitude}}","longitude":"{{$Alert.Source.Longitude}}","iprange":"{{$Alert.Source.Range}}","scenario":"{{.Scenario}}","type":"{{.Type}}","duration":"{{.Duration}}","scope":"{{.Scope}}","ip":"{{.Value}}","traefik_routers":{{ printf "%q" ($traefikRouters | uniq | join ",")}}},"values": [1],"timestamps":[{{now|unixEpoch}}000]}
                {{- end }}
                {{- end -}}
            '';
            url = "http://metrics:8428/api/v1/import";
            method = "POST";
            headers = {
              Content-Type = "application/json";
            };
          }
        ];

        profiles = [
          {
            notifications = [ "http_default" ];
            decisions = [
              {
                duration = "4h";
                type = "ban";
              }
            ];
            filters = [
              "Alert.Remediation == true && Alert.GetScope() == 'Ip'"
            ];
            name = "default_ip_remediation";
            on_success = "break";
          }
          {
            notifications = [ "http_default" ];
            decisions = [
              {
                duration = "4h";
                type = "ban";
              }
            ];
            filters = [
              "Alert.Remediation == true && Alert.GetScope() == 'Range'"
            ];
            name = "default_range_remediation";
            on_success = "break";
          }
        ];

      };

      settings = {
        general = {
          api.server.enable = true;
          prometheus = {
            enabled = true;
            level = "full";
            listen_addr = "0.0.0.0";
            listen_port = 6060;
          };
          # Needed for HTTP notifications
          plugin_config = {
            user = "crowdsec";
            group = "crowdsec";
          };
        };
        capi = {
          credentialsFile = "/var/lib/crowdsec/online_api_credentials.yaml";
        };
        lapi = {
          credentialsFile = "/var/lib/crowdsec/local_api_credentials.yaml";
        };
      };
    };

    # users.users.crowdsec.extraGroups = [ "systemd-journal" ];

    # Add ExecReload fix from nixpkgs-unstable
    systemd.services.crowdsec.serviceConfig.ExecReload = [
      "${lib.getExe' pkgs.util-linux "kill"} -HUP $MAINPID"
    ];

    services.crowdsec-firewall-bouncer = {
      enable = true;
      settings = {
        api_url = "http://127.0.0.1:8080/";
        mode = "iptables";
      };
    };

    # Configure fail2ban
    services.fail2ban = {
      enable = true;
      ignoreIP = secrets.ip-whitelist;
      bantime-increment = {
        enable = true;
        overalljails = true;
      };
      jails = {
        cal-200.settings = {
          filter = "sites-200";
          logpath = "/var/log/remote/caddy-cal.log";
          findtime = 20;
          maxretry = 10;
          bantime = 600;
          backend = "auto";
          enabled = true;
        };
        cal-404.settings = {
          filter = "sites-404";
          logpath = "/var/log/remote/caddy-cal.log";
          findtime = 20;
          maxretry = 5;
          bantime = 600;
          backend = "auto";
          enabled = true;
        };
        blog-200.settings = {
          filter = "blog-200";
          logpath = "/var/log/remote/caddy-blog.log";
          findtime = 10;
          maxretry = 50;
          bantime = 600;
          backend = "auto";
          enabled = true;
        };
        blog-404.settings = {
          filter = "blog-404";
          logpath = "/var/log/remote/caddy-blog.log";
          findtime = 10;
          maxretry = 15;
          bantime = 600;
          backend = "auto";
          enabled = true;
        };
      };
    };

    # Configure fail2ban filters
    environment.etc = {
      "fail2ban/filter.d/sites-200.conf".text = ''
        [Definition]
        failregex   = "client_ip":"<HOST>"(.*)"status":200
        datepattern = \d+
        ignoreregex =
      '';
      "fail2ban/filter.d/sites-404.conf".text = ''
        [Definition]
        failregex   = "client_ip":"<HOST>"(.*)"status":404
        datepattern = \d+
        ignoreregex =
      '';
      "fail2ban/filter.d/blog-200.conf".text = ''
        [Definition]
        failregex   = "X-Real-Ip":\["<HOST>"\](.*)"status":200
        datepattern = \d+
        ignoreregex =
      '';
      "fail2ban/filter.d/blog-404.conf".text = ''
        [Definition]
        failregex   = "X-Real-Ip":\["<HOST>"\](.*)"status":404
        datepattern = \d+
        ignoreregex =
      '';
    };

  };
}
