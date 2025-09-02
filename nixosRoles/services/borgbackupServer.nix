# custom module for borgbackup

{
  lib,
  config,
  ...
}:
let

  basePath = "/mnt/qnapBackup/borgbackup-repos";

  requireMount =
    name: cfg:
    lib.nameValuePair "borgbackup-repo-${name}" {
      requires = [ "mnt-qnapBackup.mount" ];
    };

in
{

  options = {
    roles.borgbackupServer.enable = lib.mkEnableOption "enables borgbackup module and configures repos";
  };

  config = lib.mkIf config.roles.borgbackupServer.enable {

    fileSystems."/mnt/qnapBackup" = {
      device = "192.168.50.2:/danBackup";
      fsType = "nfs";
      options = [ "rw" ];
    };

    users.users.borg = {
      createHome = true;
      home = "/home/borg";
    };

    services.borgbackup.repos = {

      test = {
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEmMnH0m2maQlZo22DLYkF7Ih/yeB1QoaqyE9SiXLvIw dan@backupBox"
        ];
        path = "${basePath}/test";
      };

      immich = {
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKmg/sxK9EJv8r5g6e8RmXWYaTBjNc3vQGy/28ptMUqZ dan@backupBox"
        ];
        path = "${basePath}/immich";
      };

      nextcloud = {
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICaie4B/gbpqgKSlf6XaunTXbL8bDCBSXsBwNXOhSKj1 dan@backupBox"
        ];
        path = "${basePath}/nextcloud";
      };

      diskyDocker = {
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJwPGfar3b6qOjU6P1Mx26Pk0Z9KkKPDHFa/3dPWZj9M dan@backupBox"
        ];
        path = "${basePath}/diskyDocker";
      };

      techDns = {
        authorizedKeys = [
          " ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIvlyShlisUwt9NVXqOeO5z0ckvEF9/D3qGzK4vS47/P dan@backupB    ox "
        ];
        path = "${basePath}/techDns";
      };

    };

    # Hopefully avoid borgbackup creating the backup directories on the local disk if/when the share fails to mount
    systemd.services = lib.mapAttrs' requireMount config.services.borgbackup.repos;
  };
}
