# default  that pulls in all other home-manager config

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
    ./programs/git.nix
    ./programs/ssh.nix
    ./sops.nix
    ./users/dan.nix
  ];

  roles = mkDefaultRoles [
    "sops"
    "git"
  ];

}
