{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.roles.flakeSettings;
in
{

  options = {
    roles.flakeSettings = {
      enable = lib.mkEnableOption "enables flake settings module";
      trimGenerations = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Automatically trim old system generations and GC on every rebuild.";
        };
        keep = lib.mkOption {
          type = lib.types.int;
          default = 3;
          description = "Number of most recent system generations to keep.";
        };
      };
    };
  };

  config = lib.mkIf config.roles.flakeSettings.enable {

    nix = {
      # Enable automatic garbage collection
      gc = lib.mkForce {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 14d";
      };
      optimise.automatic = lib.mkForce true;
      channel.enable = lib.mkForce false;
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
        download-buffer-size = 500000000; # 500 MB
      };
    };

    # Daily remove all but the configured number of system generations
    systemd.services.trim-generations = {
      description = "Trim old system generations and run GC";
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.nix}/bin/nix-env -p /nix/var/nix/profiles/system --delete-generations +${toString cfg.trimGenerations.keep}
        ${pkgs.nix}/bin/nix-collect-garbage
      '';
    };

    systemd.timers.trim-generations = {
      description = "Daily system generation trim";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
    };

  };

}
