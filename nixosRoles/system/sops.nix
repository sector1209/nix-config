# custom module for sops

{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{

  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  options = {
    roles.sops.enable = lib.mkEnableOption "enables sops-nix module";
  };

  config = lib.mkIf config.roles.sops.enable {

    environment.systemPackages = with pkgs; [
      sops
    ];

    sops.defaultSopsFile = ../../secrets/secrets.yaml;
    sops.defaultSopsFormat = "yaml";

    sops.age.keyFile = "/sops-keys/sops/age/keys.txt";

    # Testing if she works
    sops.secrets.example-key = { };

  };
}
