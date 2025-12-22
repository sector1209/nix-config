# configuration for frank

{
  ...
}:
let

  hostname = "frank";

in
{

  imports = [
    ./hardware-configuration.nix
    #./docker.nix
  ];

  boot.loader.systemd-boot.enable = true;

  networking.hostName = hostname;

  roles = {

    imperm.enable = true;

    nginx.enable = true;

  };

  services.tailscale = {
    useRoutingFeatures = "server";
    extraSetFlags = [ "--advertise-exit-node" ];
  };

  roles.services.beszel-agent.enable = true;

  users.users.dan.uid = 1000;

  system.stateVersion = "25.11";

}
