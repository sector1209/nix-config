# custom module for immich

{
  lib,
  config,
  ...
}:
{

  options = {
    roles.immich.enable = lib.mkEnableOption "enables immich module";
  };

  config = lib.mkIf config.roles.immich.enable {

    # Bring in secrets from sops
    sops.secrets = {
      "immich/db-pass" = {
        owner = config.users.users.immich.name;
      };
      "borg/immich-pass" = { };
      "borg/immich-priv" = { };
    };

    # Enable modules
    roles.nginx.enable = true;
    roles.qsv.enable = true;

    # Add immich user to shared group
    users.groups.shared.members = [ "immich" ];

    # Configure borgbackup
    #    services.borgbackup.jobs = {
    #      immichBackup = {
    #	repo = "borg@backupbox:.";
    #        paths = [ "${config.services.immich.mediaLocation}" ];
    #        doInit = true;
    #        encryption = {
    #          mode = "repokey-blake2";
    #          passCommand = "cat ${config.sops.secrets."borg/immich-pass".path}";
    #        };
    #        environment = { BORG_RSH = "ssh -i ${config.sops.secrets."borg/immich-priv".path}"; };
    #      	compression = "auto,zstd";
    #      };
    #    };

    roles.myBorgbackup.jobs.immich = {
      repo = "borg@backupbox:.";
      paths = [ "${config.services.immich.mediaLocation}" ];
      passPath = "${config.sops.secrets."borg/immich-pass".path}";
      keyPath = "${config.sops.secrets."borg/immich-priv".path}";
    };

    # Configure nginx
    services.nginx.virtualHosts."immich.danmail.me" = {
      enableACME = true;
      acmeRoot = null; # i think this makes it use DNS-01
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://0.0.0.0:${toString config.services.immich.port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
        extraConfig = ''
          	  client_max_body_size 50000M;
          	  proxy_read_timeout   600s;
          	  proxy_send_timeout   600s;
          	  send_timeout         600s;
          	'';
      };
    };

    # Enable immich user to use hardware acceleration
    users.users.immich.extraGroups = [
      "video"
      "render"
    ];

    # Configure Immich
    services.immich = {
      enable = true;
      port = 2283;
      openFirewall = true;
      secretsFile = config.sops.secrets."immich/db-pass".path;
      redis.enable = true;
      #      mediaLocation = "";
      database = {
        enable = true;
        createDB = true;
      };
      machine-learning.enable = true;
      settings = {
        server.externalDomain = "https://immich.danmail.me";
        newVersionCheck.enabled = true;
      };
    };

  };
}
