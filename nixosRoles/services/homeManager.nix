# custom module for ssh

{
  lib,
  config,
  ...
}:
{

  options = {
    roles.homeManager.enable = lib.mkEnableOption "enables ssh module";
  };

  config = lib.mkIf config.roles.homeManager.enable {

    imports = [
      inputs.home-manager.nixosModules.home-manager
    ];

    home-manager = {
      extraSpecialArgs = { inherit inputs outputs; };
      users = {
        # Import your home-manager configuration
        ${user} = import ../../../home-manager/home.nix;
      };
    };

  };
}
