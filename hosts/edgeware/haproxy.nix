{ ... }:
{

  networking.firewall.allowedTCPPorts = [
    80
    443
    25565
    25566
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
      #	      log                 /dev/log local0
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
      # use_backend darwin_backend if test_filter || cal_filter
        use_backend davis_backend if cal_filter

      #  backend darwin_backend
      #    server darwin darwin:443 send-proxy-v2

        backend davis_backend
          server mac mac:443 send-proxy-v2

        frontend mc_listen
          bind *:25565
          bind *:25566
          mode tcp

      #  acl dst_ip_arm dst_port 25566
        acl dst_ip_darm dst_port 25566
        acl dst_ip_cobbledos dst_port 25565

      #  use_backend arm_backend if dst_ip_arm
      #  server arm_mc_svr minemando-svr:25565

        use_backend darm_backend if dst_ip_darm
      #  server darm_mc_svr darm-svr:25565

      #  use_backend cobbledos_backend if dst_ip_cobbledos
      #  server cobbledos_mc_svr cobbledos_svr:25565


      #  tcp-request inpect-delay 5s
      #  tcp-request content accept if { req.ssl_hello_type 1 }

      #  default_backend mc_backend

      #  backend arm_backend
      #    mode tcp
      #    option tcp-check
      #    server minemando_svr minemando-svr:25565

        backend darm_backend
          mode tcp
          option tcp-check
          server darm_mc_svr darm-svr:25565

      #  backend cobbledos_backend
      #    mode tcp
      #    option tcp-check
      #    server cobbledos_svr cobbledos-svr:25565 
    '';
  };

}
