# custom module for nextcloud

{
  pkgs,
  lib,
  config,
  ...
}:
let
  nc-db-backup-dir = "/tmp/nextcloud-database-backup";
in
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
        "${nc-db-backup-dir}"
      ];
      passPath = "${config.sops.secrets."borg/nextcloud-pass".path}";
      keyPath = "${config.sops.secrets."borg/nextcloud-priv".path}";
      preHook = ''
        ${pkgs.coreutils}/bin/mkdir ${nc-db-backup-dir}
        ${pkgs.coreutils}/bin/chown nextcloud:nextcloud ${nc-db-backup-dir}
        ${config.services.nextcloud.occ}/bin/nextcloud-occ maintenance:mode --on
        /run/wrappers/bin/sudo -u nextcloud ${pkgs.mariadb}/bin/mysqldump --single-transaction -u nextcloud nextcloud > ${nc-db-backup-dir}/nextcloud-sqlbkp_$(date +'%Y%m%d').bak
      '';
      postHook = ''
        ${config.services.nextcloud.occ}/bin/nextcloud-occ maintenance:mode --off
        ${pkgs.coreutils}/bin/rm -rf ${nc-db-backup-dir}
      '';
    };

    # Configure nginx
    services.nginx.virtualHosts = {
      "nc.danmail.me" = {
        enableACME = true;
        acmeRoot = null; # i think this makes it use DNS-01
        forceSSL = true;
      };

    };

    # Allow nextcloud user to access /mnt/slowDisk
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
        adminpassFile = config.sops.secrets.nc-admin-pass.path;
      };

      caching.redis = true;
      configureRedis = true;

      database.createLocally = true;

      appstoreEnable = true;
      autoUpdateApps.enable = true;

    };

  };

}
