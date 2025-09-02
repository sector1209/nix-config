{
  lib,
  config,
  ...
}:
{

  options = {
    roles.flakeSettings.enable = lib.mkEnableOption "enables flake settings module";
  };

  config = lib.mkIf config.roles.flakeSettings.enable {

    # Opinionated: make flake registry and nix path match flake inputs
    #      registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    #      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    #    };

    # Enable automatic garbage collection
    nix = {
      gc = lib.mkForce {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
      optimise.automatic = lib.mkForce true;
      channel.enable = lib.mkForce false;
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
      };
    };
  };

}
