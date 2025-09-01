# custom module for deploying machine

{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{

  options = {
    roles.deployMachine.enable = lib.mkEnableOption "enables deployment machine module";
  };

  config = lib.mkIf config.roles.deployMachine.enable {

    environment.systemPackages = with pkgs; [
      nixos-anywhere
      nh
      nixos-generators
      nixfmt-tree
      pre-commit
      custom.nix-output-monitor
      custom.rebuild
      custom.rebuild-remote
    ];

  };
}
