{ secrets, ... }:
{

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
      # HTTPS / SNI-based routing (Tailscale backend "mac")
      #---------------------------------------------------------------------
      map $ssl_preread_server_name $https_backend {
        cal.danmail.me    mac_upstream;
        blog.danmail.me   mac_upstream;
        # No default entry: unmatched SNI is dropped.
      }

      upstream mac_upstream {
        server mac:443;
      }

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

      local5.*     /var/log/haproxy.log

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

}
