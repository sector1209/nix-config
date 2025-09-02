# Default module that imports all custom modules

{
  modulesPath,
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  ...
}:
let

in
{

  imports = [
    ./system
    ./services
    ./options
  ];

  roles = {

    sops.enable = lib.mkDefault true;

    flakeSettings.enable = lib.mkDefault true;

    updateSettings.enable = lib.mkDefault true;

    localisation.enable = lib.mkDefault true;

    packages.enable = lib.mkDefault true;

    networking.enable = lib.mkDefault true;

    users.enable = lib.mkDefault true;

    aliases.enable = lib.mkDefault true;

    fonts.enable = lib.mkDefault true;

    #  nvf.enable =
    #    lib.mkDefault true;

    # Disabled as causing nodejs_18 issues with nixpkgs 25.05
    nixvim.enable = lib.mkDefault true;

    fish.enable = lib.mkDefault true;

    ssh.enable = lib.mkDefault true;

    tailscale.enable = lib.mkDefault true;

    deployUser.enable = lib.mkDefault true;

    prometheus-exporter.enable = lib.mkDefault true;

    promtail.enable = lib.mkDefault true;

  };

  documentation.nixos.enable = true;

}
