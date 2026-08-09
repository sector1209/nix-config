# Role module for edge proxy

{
  lib,
  config,
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

        # Separate Caddy logs by tag
        if $programname == 'caddy-cal' then /var/log/remote/caddy-cal.log
        & stop

        if $programname == 'caddy-blog' then /var/log/remote/caddy-blog.log
        & stop
      '';
    };

    preservation.preserveAt."/persist" = {
      directories = [
        "/var/lib/fail2ban"
      ];
    };

    # Configure fail2ban
    services.fail2ban = {
      enable = true;
      ignoreIP = [ "100.0.0.0/8" ] ++ secrets.fail2ban-whitelist;
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
