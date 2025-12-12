{
  pkgs,
  lib,
  config,
  ...
}:
{

  sops.secrets = {
    "podman-davis/davis-admin-pass" = { };
    "podman-davis/mysql-pass" = { };
  };

  sops.templates."davis-envFile".content = ''
    ADMIN_PASS=${config.sops.placeholder."podman-davis/davis-admin-pass"}
    MYSQL_PASS=${config.sops.placeholder."podman-davis/mysql-pass"}
  '';

  sops.templates."davis-envFile".owner = config.users.users.podman.name;

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
    allowedUDPPorts = [
      80
      443
    ];
  };

  roles.acme.enable = true;

  security.acme.defaults.reloadServices = [ "caddy.service" ];

  # ACME service for SSL certificate
  security.acme = {
    certs."cal.danmail.me" = {
      group = config.services.caddy.group;
    };
  };

  # New Caddy config
  services.caddy = {
    enable = true;
    globalConfig = ''
      	servers :443 {
      	  name proxied_https
      	  listener_wrappers {
      	    proxy_protocol {
      	      timeout 5s
      	      allow 100.0.0.0/8
      	    }
      	  tls
         }
      	}
      	# log default {
      	#   output stdout
      	#   level INFO
      	# }
    '';
    virtualHosts."cal.danmail.me" = {
      extraConfig = ''
        	redir /.well-known/carddav /dav/ 301
        	redir /.well-known/caldav /dav/ 301
        	log {
        	  output stdout
        	  level INFO
        	}
        	tls /var/lib/acme/cal.danmail.me/cert.pem /var/lib/acme/cal.danmail.me/key.pem
        	@blocked {
        	  not remote_ip private_ranges 100.0.0.0/8
        	  path /login /dashboard
        	}
        	respond @blocked 403
        	#log {
        	#output file /var/log/davis/access.log
        	#  format transform "{common_log}" {
        	#    time_local
        	#  }
         #}
        	reverse_proxy localhost:9000
      '';
    };
  };

  # Define directories to persist between reboots
  environment.persistence."/persist/system" = {
    directories = [
      {
        directory = "/home/dan/.local/share/containers";
        user = "dan";
        group = "users";
        mode = "u=rwx,g=rx,o=";
      }
      {
        directory = "/home/podman/.local/share/containers";
        user = "podman";
        group = "podman";
        mode = "u=rwx,g=rx,o=";
      }
      "/var/lib/acme"
    ];
  };

  users.mutableUsers = false;

  # User configuration administrative dan user
  users.users.dan = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "systemd-journal"
    ];
  };

  # User configuration for locked-down podman user
  users.users.podman = {
    uid = 990;
    group = "podman";
    isSystemUser = true;
    home = "/home/podman";
    createHome = true;
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
    useDefaultShell = true;
    linger = true;
  };

  # System-wide podman configuration (no user specified)
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    defaultNetwork.settings = {
      dns_enabled = true;
    };
  };

  system.activationScripts.ensurePodmanWrappers = {
    text = ''
      # Ensure wrappers directory exists
      mkdir -p /run/wrappers/bin

      # Force recreate the setuid wrappers
      cp ${pkgs.shadow}/bin/newuidmap /run/wrappers/bin/newuidmap
      chmod 4755 /run/wrappers/bin/newuidmap
      chown root:root /run/wrappers/bin/newuidmap

      cp ${pkgs.shadow}/bin/newgidmap /run/wrappers/bin/newgidmap
      chmod 4755 /run/wrappers/bin/newgidmap
      chown root:root /run/wrappers/bin/newgidmap

      # Verify they're setuid
      ls -la /run/wrappers/bin/new{u,g}idmap
    '';
    deps = [ "specialfs" ];
  };

  # Enable container name DNS for non-default Podman networks
  networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

  # USER SERVICES CONFIGURATION

  # Network creation user service
  systemd.user.services."podman-network-davis_davis_compose" = {
    path = [
      pkgs.podman
      pkgs.shadow
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.podman}/bin/podman network rm -f davis_davis_compose";
    };
    script = ''
      export PATH="/run/wrappers/bin:$PATH"
      #which newuidmap
      ${pkgs.podman}/bin/podman network inspect davis_davis_compose || \
      ${pkgs.podman}/bin/podman network create davis_davis_compose
    '';
    unitConfig = {
      ConditionUser = "podman";
    };
    partOf = [ "podman-compose-davis.target" ];
    wantedBy = [ "podman-compose-davis.target" ];
  };

  # MySQL database container user service
  systemd.user.services."podman-mysql-davis" = {
    path = [
      pkgs.podman
      pkgs.bash
      pkgs.shadow
    ];
    environment = {
      PATH = lib.mkForce "/run/wrappers/bin:/run/current-system/sw/bin:/usr/bin:/bin";
    };
    serviceConfig = {
      EnvironmentFile = "${config.sops.templates."davis-envFile".path}";
      Type = "notify";
      NotifyAccess = "all";
      KillMode = "mixed";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStartSec = 900;
      TimeoutStopSec = 70;
      ExecStartPre = [
        # Remove any existing container
        "-${pkgs.podman}/bin/podman rm -f mysql-davis"
        # Pull image if needed
        #"${pkgs.podman}/bin/podman pull docker.io/library/mysql:8.0"
        # Create volume if it doesn't exist
        "${pkgs.bash}/bin/bash -c '${pkgs.podman}/bin/podman volume create mysql-davis-data || true'"
      ];
      ExecStart = ''
        ${pkgs.podman}/bin/podman run \
                --name mysql-davis \
                --rm \
                --log-driver journald \
        #        --cgroups=no-conmon \
        	--cgroup-manager=cgroupfs \
                --sdnotify=conmon \
                --cidfile=%t/mysql-davis.ctr-id \
                --replace \
                --detach \
                --network davis_davis_compose \
                --volume mysql-davis-data:/var/lib/mysql \
                --publish 3306:3306 \
        	-e MYSQL_DATABASE=davis \
        	-e MYSQL_PASSWORD=''${MYSQL_PASS} \
        	-e MYSQL_ROOT_PASSWORD=''${MYSQL_PASS} \
        	-e MYSQL_USER=davis_user \
                mysql:8.0'';
      ExecStop = "${pkgs.podman}/bin/podman stop --ignore --cidfile=%t/mysql-davis.ctr-id";
      ExecStopPost = [
        "${pkgs.podman}/bin/podman rm -f --ignore --cidfile=%t/mysql-davis.ctr-id"
        "-${pkgs.coreutils}/bin/rm -f %t/mysql-davis.ctr-id"
      ];
    };
    unitConfig = {
      ConditionUser = "podman";
    };
    partOf = [ "podman-compose-davis.target" ];
    wantedBy = [ "podman-compose-davis.target" ];
    # MySQL should start before Davis app
    before = [ "podman-davis-standalone.service" ];
  };

  # Davis container user service
  systemd.user.services."podman-davis-standalone" = {
    path = [ pkgs.podman ];
    environment = {
      PATH = lib.mkForce "/run/wrappers/bin:/run/current-system/sw/bin:/usr/bin:/bin";
    };
    serviceConfig = {
      EnvironmentFile = "${config.sops.templates."davis-envFile".path}";
      Type = "notify";
      NotifyAccess = "all";
      KillMode = "mixed";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStartSec = 900;
      TimeoutStopSec = 70;
      ExecStartPre = [
        # Remove any existing container
        "-${pkgs.podman}/bin/podman rm -f davis-standalone"
        # Pull image if needed
        "${pkgs.podman}/bin/podman pull ghcr.io/tchapi/davis-standalone:latest"
      ];
      ExecStart = ''
        ${pkgs.podman}/bin/podman run \
                --name davis-standalone \
                --rm \
                --log-driver journald \
                --cgroups=no-conmon \
                --sdnotify=conmon \
                --cidfile=%t/davis-standalone.ctr-id \
                --replace \
                --detach \
        	--network davis_davis_compose \
                --publish 9000:9000 \
        	-e APP_ENV=prod \
        	-e ADMIN_LOGIN=admin \
        	-e ADMIN_PASSWORD=''${ADMIN_PASS} \
        	-e APP_ENV=prod \
        	-e APP_TIMEZONE=Europe/London \
        	-e AUTH_METHOD=Basic \
        	-e AUTH_REALM=SabreDAV \
        	-e CALDAV_ENABLED=true \
        	-e CARDDAV_ENABLED=false \
        	-e DATABASE_DRIVER=mysql \
        	-e DATABASE_URL=mysql://davis_user:''${MYSQL_PASS}@mysql-davis:3306/davis?serverVersion=mariadb-10.6.10&charset=utf8mb4 \
        	-e INVITE_FROM_ADDRESS=no-reply@example.org \
        	-e MAILER_DSN=smtp://userdav:test@smtp.myprovider.com:587 \
        	-e WEBDAV_ENABLED=false \
        	-e WEBDAV_PUBLIC_DIR=/webdav \
        	-e WEBDAV_TMP_DIR=/tmp \
                ghcr.io/tchapi/davis-standalone:latest'';
      ExecStop = "${pkgs.podman}/bin/podman stop --ignore --cidfile=%t/davis-standalone.ctr-id";
      ExecStopPost = [
        "${pkgs.podman}/bin/podman rm -f --ignore --cidfile=%t/davis-standalone.ctr-id"
        "-${pkgs.coreutils}/bin/rm -f %t/davis-standalone.ctr-id"
      ];
    };
    unitConfig = {
      ConditionUser = "podman";
    };
    partOf = [ "podman-compose-davis.target" ];
    wantedBy = [ "podman-compose-davis.target" ];
  };

  # User target for managing the compose stack
  systemd.user.targets."podman-compose-davis" = {
    description = "Davis Podman Compose Stack";
    unitConfig = {
      ConditionUser = "podman";
    };
    wantedBy = [ "default.target" ];
  };

  # Optional: User systemd configuration
  systemd.user.extraConfig = ''
    DefaultTimeoutStartSec=900s
    DefaultTimeoutStopSec=70s
  '';

}
