{
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
  ];

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
