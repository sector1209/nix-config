# configuration for charlie

{
  lib,
  pkgs,
  ...
}:
let

  hostname = "charlie";

in
{

  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = hostname;

  ### Enable roles

  roles = {

    proxmoxContainer = {
      enable = true;
      privilaged = true;
    };

    jellyfin.enable = true;

    nextcloud.enable = true;

    immich.enable = true;

    nginx.enable = true;

    beszel-agent.extraFilesystems = [
      "/var/lib/nextcloud__Nextcloud Mount"
    ];

  };

  # Enable Beszel agent GPU monitoring
  services.beszel.agent = {
    environment = {
      LOG_LEVEL = "debug";
      GPU_COLLECTOR = "intel_gpu_top";
    };
    extraPath = [
      # Not needed if using services.xserver.videoDrivers
      pkgs.intel-gpu-tools
    ];
  };

  systemd.services.beszel-agent.serviceConfig = {
    # Enable CAP_PERFMON in service unit
    AmbientCapabilities = [ "CAP_PERFMON" ];
    # Drop all capabilities except CAP_PERFMON
    CapabilityBoundingSet = [ "CAP_PERFMON" ];
    # Prevent namespace scoping
    PrivateUsers = lib.mkForce false;
    # Allow Beszel agent to access devices
    PrivateDevices = lib.mkForce false;
    # Prevent filtering of perf_event_open system calls
    SystemCallFilter = lib.mkForce [
      "@system-service"
      "perf_event_open"
    ];
  };

  system.stateVersion = "24.11";

}
