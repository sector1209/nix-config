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

    # enable vaapi on OS-level
    #    nixpkgs.config.packageOverrides = pkgs: {
    #      vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
    #    };

    systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD"; # Or "i965" if using older driver

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    }; # Same here

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # For Broadwell (2014) or newer processors. LIBVA_DRIVER_NAME=iHD
        #        intel-vaapi-driver # previously vaapiIntel
        #       vaapiVdpau
        libva-vdpau-driver # Previously vaapiVdpau
        #        libvdpau-va-gl
        intel-compute-runtime-legacy1
        #        intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
        #        vpl-gpu-rt # QSV on 11th gen or newer
        #        intel-media-sdk # QSV up to 11th gen
        intel-ocl # OpenCL support
      ];
    };

    nixpkgs.config.allowUnfree = true;

    # map the render and video groups to the gids of the proxmox host
    users.groups = {
      render.gid = lib.mkForce 104;
      video.gid = lib.mkForce 44;
    };

  };
}
