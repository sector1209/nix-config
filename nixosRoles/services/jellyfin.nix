{
  lib,
  config,
  secrets,
  ...
}:
{

  options = {
    roles.jellyfin.enable = lib.mkEnableOption "enables jellyfin module";
    #    qsv.enable = true;
  };

  config = lib.mkIf config.roles.jellyfin.enable {

    fileSystems."/mnt/diskyMediaShare" = {
      device = "${secrets.lanIp.dennis}:/export/diskyMedia";
      fsType = "nfs";
      options = [
        "rw"
        "vers=3"
        "proto=tcp"
        "nolock"
        "_netdev"
      ];
    };

    roles.nginx.enable = true;
    roles.qsv.enable = true;

    users.groups.shared.members = [
      "dan"
      "jellyfin"
    ];

    services.jellyfin = {
      enable = true;
      openFirewall = true;
      #      dataDir = "/mnt/slowDisk/jellyfin";
    };

    users.users.jellyfin.extraGroups = [
      "render"
      "video"
    ];

    services.nginx.virtualHosts = {
      "jellyfin.c.danmail.me" = {
        serverAliases = [ "jellyfin.danmail.me" ];
        enableACME = true;
        acmeRoot = null;
        addSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:8096";
          proxyWebsockets = true;
        };
      };
    };
  };

}
