{
  pkgs,
  lib,
  config,
  ...
}:
{

  options = {
    roles.qsv.enable = lib.mkEnableOption "enables qsv module";
  };

  config = lib.mkIf config.roles.qsv.enable {

    systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD"; # Or "i965" if using older driver

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    }; # Same here

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # The core QuickSync driver. VA-API support for Broadwell (2014) or newer processors. LIBVA_DRIVER_NAME=iHD
        intel-compute-runtime-legacy1 # OpenCL filter support for Gen8,9,11 GPUs (hardware tonemapping and subtitle burn-in)
        intel-ocl # OpenCL support
      ];
    };

    nixpkgs.config.allowUnfree = true;

    # Map the render and video groups to the GIDs on the Proxmox host
    users.groups = {
      render.gid = lib.mkForce 104;
      video.gid = lib.mkForce 44;
    };

  };
}
