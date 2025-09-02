{
  lib,
  config,
  ...
}:
{

  options = {
    roles.jellyfin.enable = lib.mkEnableOption "enables jellyfin module";
    #    qsv.enable = true;
  };

  config = lib.mkIf config.roles.jellyfin.enable {

    fileSystems."/mnt/diskyMediaShare" = {
      device = "192.168.50.105:/export/diskyMedia";
      fsType = "nfs";
      options = [ "rw" ];
    };

    #    fileSystems."/mnt/diskyBizShare" = {
    #      device = "192.168.50.105:/export/diskyBiz";
    #      fsType = "nfs";
    #      options = [ "rw" ];
    #    };

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
        };
      };
    };
  };

}
