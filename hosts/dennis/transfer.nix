{
  secrets,
  ...
}:
{

  # Bind mount media dirs to /export/
  fileSystems."/export/diskyMedia" = {
    device = "/mnt/diskyMedia";
    fsType = "btrfs";
    options = [ "bind" ];
  };

  services.nfs.server = {
    enable = true;
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
    # extraNfsdConfig = "";
  };

  services.nfs.server.exports = ''
    /export/diskyMedia  ${secrets.lanIp.charlie}(rw,nohide,insecure,no_subtree_check,all_squash,anonuid=166535,anongid=166535)
  '';

  # for nfsv4
  # networking.firewall.allowedTCPPorts = [ 2049 ];

  # for NFSv3; view with `rpcinfo -p`
  networking.firewall = {

    allowedTCPPorts = [
      111
      2049
      4000
      4001
      4002
      20048
    ];
    allowedUDPPorts = [
      111
      2049
      4000
      4001
      4002
      20048
    ];

  };

}
