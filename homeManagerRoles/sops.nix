# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  config,
  lib,
  ...
}:
let

  roleName = "sops";

in
{

  # You can import other home-manager modules here
  imports = [
    inputs.nix-secrets.homeManagerModules.nas
  ];

  options = {
    roles.${roleName}.enable = lib.mkEnableOption "enables ${roleName} role";
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    # Testing if she works
    sops.secrets.example-key = { };

  };

}
