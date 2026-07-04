# custom module for deploying machine

{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.roles.deployMachine;
in
{

  options = {
    roles.deployMachine = {
      enable = lib.mkEnableOption "enables deployment machine module";
      devUser = lib.mkOption {
        type = lib.types.str;
        default = "dan";
      };
    };
  };

  config = lib.mkIf config.roles.deployMachine.enable {

    environment.systemPackages = with pkgs; [
      nixos-anywhere
      jq # Needed for nixos-anywhere script
      nh
      nixos-generators
      nixfmt-tree
      pre-commit
      custom.nix-output-monitor
      custom.rebuild
      custom.rebuild-remote
      gcc # Needed for deadnix pre-commit plugin
      nixd
      nil
      nixfmt
      shfmt
    ];

    # Allow Zed Editor remote server to function properly
    programs = {
      nix-ld.enable = true;
    };

    preservation.preserveAt."/persist".users.${cfg.devUser}.directories = [
      ".zed_server"
    ];

  };
}
