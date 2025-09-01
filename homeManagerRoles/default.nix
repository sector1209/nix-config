# default  that pulls in all other home-manager config

{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{

  #  home-manager.dan = {
  #    extraSpecialArgs = { inherit inputs; };
  #    users = {
  #      modules = [
  #        ./home.nix
  #	inputs.self.outputs.homeManagerModules.default
  #	./programs/ssh.nix
  #      ];
  #    };
  #  };
  #}

  imports = [
    #    ./home.nix
    ./programs/git.nix
    ./sops.nix
    ./users/dan.nix
  ];

}
