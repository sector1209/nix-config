# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  ...
}:
{

  # You can import other home-manager modules here
  imports = [
    inputs.nix-secrets.homeManagerModules.nas
  ];

  # Testing if she works
  sops.secrets.example-key = { };

}
