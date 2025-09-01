# custom module for nextcloud

{
  pkgs,
  lib,
  config,
  modulesPath,
  inputs,
  outputs,
  ...
}:
{
  # ADD NEXTCLOUD-DATABASE-BACKUP-DIR AS A VARIABLE

  options = {
    roles.nextcloud.enable = lib.mkEnableOption "enables nextcloud module";
  };

  config = lib.mkIf config.roles.nextcloud.enable {

    sops.secrets.nc-admin-pass = {
      owner = config.users.users.nextcloud.name;
    };

    sops.secrets = {
      "borg/nextcloud-pass" = { };
      "borg/nextcloud-priv" = { };
      jwt-secret = { };
    };

    # Enable roles
    roles.nginx.enable = true;

    roles.myBorgbackup.jobs.nextcloud = {
      repo = "borg@backupbox:.";
      paths = [
        "${config.services.nextcloud.home}"
        "/home/dan/nextcloud-database-backup"
      ];
      passPath = "${config.sops.secrets."borg/nextcloud-pass".path}";
      keyPath = "${config.sops.secrets."borg/nextcloud-priv".path}";
      preHook = "${config.services.nextcloud.occ}/bin/nextcloud-occ maintenance:mode --on\n/run/wrappers/bin/sudo -u nextcloud /run/current-system/sw/bin/mysqldump --single-transaction -u nextcloud nextcloud > /home/dan/nextcloud-database-backup/nextcloud-sqlbkp_$(date +'%Y%m%d').bak"; # Should probably replace sudo and mysqldump commands with something more nixy https://discourse.nixos.org/t/get-executable-path-of-pkgs-writescriptbin-nextcloud-occ/32339
      postHook = "${config.services.nextcloud.occ}/bin/nextcloud-occ maintenance:mode --off";
    };

    # Enable borgbackup for nextcloud (and database maybe)
    #    services.borgbackup.jobs = {
    #      nextcloudBackup = {
    #        repo = "borg@backupbox:.";
    #      archiveBaseName = "testBackup";
    #        paths = [ "${config.services.nextcloud.home}" "/home/dan/nextcloud-database-backup" ];
    #        doInit = true;
    #        encryption = {
    #          mode = "repokey-blake2";
    #          passCommand = "cat ${config.sops.secrets."borg/nextcloud-pass".path}";
    #        };
    #        environment = { BORG_RSH = "ssh -i ${config.sops.secrets."borg/nextcloud-priv".path}"; };
    #        compression = "auto,zstd";
    #	prune.keep = {
    #	  within = "1d"; # Keep all archives from the last day
    #	  daily = 7;
    #	  weekly = 4;
    #	  monthly = -1; # Keep at least one archive for each month
    #	};
    #	preHook = "${config.services.nextcloud.occ}/bin/nextcloud-occ maintenance:mode --on\n/run/wrappers/bin/sudo -u nextcloud /run/current-system/sw/bin/mysqldump --single-transaction -u nextcloud nextcloud > /home/dan/nextcloud-database-backup/nextcloud-sqlbkp_$(date +'%Y%m%d').bak"; # Should probably replace sudo and mysqldump commands with something more nixy https://discourse.nixos.org/t/get-executable-path-of-pkgs-writescriptbin-nextcloud-occ/32339
    #	postHook = "${config.services.nextcloud.occ}/bin/nextcloud-occ maintenance:mode --off";
    #      };
    #    };

    # Configure nginx
    services.nginx.virtualHosts = {
      "nc.danmail.me" = {
        enableACME = true;
        acmeRoot = null; # i think this makes it use DNS-01
        forceSSL = true;
      };

      #      "onlyoffice.danmail.me" = {
      #	enableACME = true;
      #	acmeRoot = null;
      #	forceSSL = true;
      #	locations."/" = {
      #	  proxyPass = "http://127.0.0.1:${toString config.services.onlyoffice.port}";
      #	};
      #	listen = [ { addr = "127.0.0.1"; port = 8000; } ];
      #      };

    };

    # Allow nextcloud user to access /mnt/slowDisk
    #    users.users.nextcloud.extraGroups = [ "shared" ];
    users.groups.shared.members = [
      "nextcloud"
      "nextcloud-redis"
    ];

    # Set up Nextcloud
    services.nextcloud = {
      enable = true;
      hostName = "nc.danmail.me";

      # Need to manually increment with every major upgrade.
      package = pkgs.nextcloud31;

      https = true;
      maxUploadSize = "100G"; # increase max upload size to avoid problems uploading videos

      # Fix error related to php options
      phpOptions."opcache.interned_strings_buffer" = "13";

      #     home = "/mnt/slowDisk/nextcloud";
      #     datadir = "/mnt/slowDisk/nextcloudData";

      settings = {
        overwriteProtocol = "https";
        trusted_proxies = [
          "192.168.50.0/24"
          "0.0.0.0/0"
        ];
        default_phone_region = "GB";
        maintenance_window_start = 2; # 02:00
        filelocking.enabled = true;
        log_type = "file"; # Fix error message: https://github.com/NixOS/nixpkgs/issues/306003
        loglevel = 1;
      };

      nginx = {
        recommendedHttpHeaders = true;
      };

      config = {
        dbtype = "mysql"; # Actually installs mariadb behind the scenes
        dbuser = "nextcloud";
        dbname = "nextcloud";
        #	dbpassFile = "/home/dan/nixos-configs/keys/nc-db-pass";
        #	adminpassFile = "/home/dan/nixos-configs/keys/nc-admin-pass";
        #	adminpassFile = "${pkgs.writeText "adminpass" "7aqC5pr6PBzXOrNxdpyO3tXA7FT0"}";
        adminpassFile = config.sops.secrets.nc-admin-pass.path;
      };

      caching.redis = true;
      configureRedis = true;

      database.createLocally = true;

      appstoreEnable = true;
      autoUpdateApps.enable = true;

    };

    #    networking.firewall.allowedTCPPorts = [ 8000 ];

    # Enable onlyoffice service
    #    services.onlyoffice = {
    #      enable = true;
    #      hostname = "onlyoffice.danmail.me";
    #      jwtSecretFile = config.sops.secrets.jwt-secret.path;
    #    };

    #    services.epmd.listenStream = "0.0.0.0:4369"; # Fix error when enabling onlyoffice: - epmd listens by default on ipv6, enable ipv6 or change config.services.epmd.listenStream

    # Allow unfree package corefonts-1 to fix error
    #    nixpkgs.config.allowUnfreePredicate = pkg:
    #    builtins.elem (lib.getName pkg) [
    # Add additional package names here
    #      "corefonts"
    #    ];

    # Okay so there's this bug with onlyoffice at the moment: https://github.com/NixOS/nixpkgs/issues/352443
    # Until the fix gets merged it seems easier to just run it in a container on dennis (suggested in the same thread)

  };

}
