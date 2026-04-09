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
      GPU_COLLECTOR = "intel_gpu_top";
    };
    extraPath = [
      pkgs.intel-gpu-tools
    ];
  };

  # Install intel_gpu_top
  environment.systemPackages = [
    pkgs.intel-gpu-tools
  ];

  systemd.services.beszel-agent.serviceConfig = {
    # Enable CAP_PERFMON in service unit
    AmbientCapabilities = [ "CAP_PERFMON" ];
    CapabilityBoundingSet = [ "CAP_PERFMON" ];
    # Allow privilages to be inherited by child processes
    NoNewPrivileges = lib.mkForce false;
    # Prevent namespace scoping
    PrivateUsers = lib.mkForce false;
    # Allow Beszel agent to access devices generally
    PrivateDevices = lib.mkForce false;
    # Allow Beszel agent access to Intel GPU devices
    DeviceAllow = [
      "/dev/dri/card1 rw"
      "/dev/dri/renderD128 rw"
    ];
    # Prevent filtering of perf_event_open system calls
    SystemCallFilter = lib.mkForce [
      "@system-service"
      "perf_event_open"
    ];
  };

  system.stateVersion = "24.11";

}
