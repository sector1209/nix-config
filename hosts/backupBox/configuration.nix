{
  ...
}:
let
  hostname = "backupBox";
in
{

  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = hostname;

  roles = {
    proxmoxContainer = {
      enable = true;
      privilaged = true;
    };
    borgbackupServer.enable = true;
    beszel-agent.extraFilesystems = [ "/mnt/qnapBackup" ];
  };

  system.stateVersion = "24.11";

}
