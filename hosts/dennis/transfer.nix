{
  ...
}:
{

  # Bind mount media dirs to /export/
  fileSystems."/export/diskyMedia" = {
    device = "/mnt/diskyMedia";
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
    /export         192.168.50.125(rw,fsid=0,no_subtree_check,all_squash,anonuid=1001,anongid=1001)
    /export/diskyMedia  192.168.50.209(rw,nohide,insecure,no_subtree_check,all_squash,anonuid=166535,anongid=166535)
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
