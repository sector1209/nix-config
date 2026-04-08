# configuration for frank

{
  lib,
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

  users.users.dan.uid = 1000;

  # Disable motherboard RGB
  services.hardware.openrgb = {
    enable = true;
    motherboard = "intel";
  };

  # Enable Nvidia drivers
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = false;
  nixpkgs.config.allowUnfree = true;

  # Enable Beszel agent GPU monitoring
  services.beszel.agent = {
    environment = {
      GPU_COLLECTOR = "nvidia-smi";
    };
  };

  systemd.services.beszel-agent.serviceConfig = {
    # Allow Beszel agent to access devices
    PrivateDevices = lib.mkForce false;
    # Allow Beszel agent access to Nvidia GPU
    DeviceAllow = [
      "/dev/nvidiactl rw"
      "/dev/nvidia0 rw"
    ];
  };

  system.stateVersion = "25.11";

}
