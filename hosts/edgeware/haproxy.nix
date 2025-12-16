{ ... }:
{

  networking.firewall.allowedTCPPorts = [
    80
    443
    25565
    25566
    514
  ];

  services.haproxy = {
    enable = true;
    config = ''
            #---------------------------------------------------------------------
            # Global settings
            #---------------------------------------------------------------------
            global
      	      daemon
      #	      user                haproxy
      #	      group               haproxy
       	      log                 /dev/log local5
              #log 127.0.0.1 local5
      #	      maxconn             5000
      #	      chroot              /var/lib/haproxy
      #	      pidfile             /var/run/haproxy.pid

            #---------------------------------------------------------------------
            # common defaults
            #---------------------------------------------------------------------
            defaults
      	      mode                 tcp
      	      log                  global
      	      option               tcplog
      	      timeout connect      5s
      	      timeout client       10s
      	      timeout server       10s

            #---------------------------------------------------------------------
            # dedicated stats page
            #---------------------------------------------------------------------
            #listen stats
      	  #mode http
      	  #bind :22222
      	  #stats enable
      	  #stats uri            /haproxy?stats
      	  #stats realm          Haproxy\ Statistics
      	  #stats refresh        30s

            #listen stats
            # bind :9000
            # mode http
            # stats enable
            # stats hide-version
            # stats realm Haproxy\ Statistics
            # stats uri /haproxy_stats


            #---------------------------------------------------------------------
            # main frontend which proxys to the backends
            #---------------------------------------------------------------------

        frontend main_https_listen
          bind *:443
          mode tcp

        # Wait for a client hello for at most 5 seconds
        tcp-request inspect-delay 5s
        tcp-request content accept if { req.ssl_hello_type 1 }

        acl test_filter req_ssl_sni -i test.danmail.me
        acl cal_filter req_ssl_sni -i cal.danmail.me
        acl blog_filter req_ssl_sni -i blog.danmail.me
      # use_backend darwin_backend if test_filter || cal_filter
        use_backend davis_backend if cal_filter
        use_backend blog_backend if blog_filter

        backend davis_backend
          server mac mac:443 send-proxy-v2

        backend blog_backend
          server mac mac:443 send-proxy-v2

        frontend mc_listen
          bind *:25565
          bind *:25566
          mode tcp

        #acl dst_ip_darm dst_port 25566
        acl dst_ip_firelink dst_port 25565

        #use_backend darm_backend if dst_ip_darm

        use_backend firelink_backend if dst_ip_firelink

      #  default_backend mc_backend

        #backend darm_backend
        #  mode tcp
        #  option tcp-check
        #  server darm_mc_svr darm-svr:25565

        backend firelink_backend
          mode tcp
          option tcp-check
          server firelink_svr firelink-svr:25565
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

  # Configure persistence for fail2ban
  environment.persistence."/persist/system" = {
    hideMounts = true;
    directories = [
      "/var/lib/fail2ban"
    ];
  };

  # Configure fail2ban
  services.fail2ban = {
    enable = true;
    ignoreIP = [ "100.0.0.0/8" ];
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
        filter = "sites-200";
        logpath = "/var/log/remote/caddy-blog.log";
        findtime = 10;
        maxretry = 50;
        bantime = 600;
        backend = "auto";
        enabled = true;
      };
      blog-404.settings = {
        filter = "sites-404";
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
  };

}
