# Default module that imports all custom modules

{
  lib,
  ...
}:
let

  helpers = import ./rolesHelpers.nix lib;
  inherit (helpers) mkDefaultRoles;

in
{

  imports = [
    ./system
    ./services
    ./options
  ];

  roles = mkDefaultRoles [
    "beszel-agent"
    "sops"
    "flakeSettings"
    "updateSettings"
    "localisation"
    "packages"
    "networking"
    "users"
    "aliases"
    "fonts"
    "nixvim"
    "fish"
    "ssh"
    "tailscale"
    "deployUser"
    "prometheus-exporter"
    "grafana-alloy"
  ];

  documentation.nixos.enable = true;

}
