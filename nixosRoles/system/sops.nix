# custom module for sops

{
  lib,
  config,
  inputs,
  ...
}:
{

  imports = [
    inputs.nix-secrets.nixosModules.nas
  ];

  options = {
    roles.sops.enable = lib.mkEnableOption "enables sops-nix module";
  };

  config = lib.mkIf config.roles.sops.enable {

    # Testing if she works
    sops.secrets.example-key = { };

  };
}
