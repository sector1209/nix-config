# Role module for edge proxy

{
  lib,
  config,
  secrets,
  ...
}:
let

  roleName = "edgeProxy";

  cfg = config.roles.${roleName};

  # Get each instance of cfg.virtualHosts
  virtualHosts = builtins.attrNames cfg.virtualHosts;

  # Make a list pairing virtualHost to destination
  mapList = lib.map (
    vHost:
    (
      "${vHost} ${
        if cfg.virtualHosts.${vHost}.useUpstream then
          (lib.concatStringsSep "_" [
            (builtins.elemAt (lib.strings.splitString ":" cfg.virtualHosts.${vHost}.destination) 0)
            "upstream"
          ])
        else
          (cfg.virtualHosts.${vHost}.destination)
      };"
    )
  ) virtualHosts;

  # Make the map of SRI destination to backend
  mkMap = lib.concatLines [
    "map $ssl_preread_server_name $https_backend {"
    (lib.trim (lib.concatLines mapList))
    "}"
  ];

  # Filter virtualHosts with useUpstream
  filteredVirtualHosts = lib.filter (vHost: cfg.virtualHosts.${vHost}.useUpstream) virtualHosts;

  # Get the destination of each filtered host
  destinationList = lib.lists.unique (
    lib.map (vHost: "${cfg.virtualHosts.${vHost}.destination}") filteredVirtualHosts
  );

  # Create an upstream block for each filtered virtualHost
  upstreamBlocks = lib.map (
    destination:
    (lib.concatLines (
      let
        splitDestination = builtins.elemAt (lib.strings.splitString ":" destination) 0;
      in
      [
        "upstream ${splitDestination}_upstream {"
        "  server ${destination};"
        "}"
      ]
    ))
  ) destinationList;

  # Make the upstream blocks
  mkUpstreamBlocks = lib.concatLines upstreamBlocks;

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
