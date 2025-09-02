# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  ...
}:
{

  # You can import other home-manager modules here
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops.defaultSopsFile = ../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.age.keyFile = "/sops-keys/sops/age/keys.txt";

  # Testing if she works
  sops.secrets.example-key = { };
  #    sops.secrets."myservice/my_subdir/my_secret" = { };

}
