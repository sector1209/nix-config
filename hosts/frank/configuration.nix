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

    technitium-dns = {
      enable = true;
      hostName = "dns2";
    };

  };

  services.tailscale = {
    useRoutingFeatures = "server";
    extraSetFlags = [ "--advertise-exit-node" ];
  };

  roles.services.beszel-agent.enable = true;

  users.users.dan.uid = 1000;

  # Disable motherboard RGB
  services.hardware.openrgb = {
    enable = true;
    motherboard = "intel";
  };

  system.stateVersion = "25.11";

}
