# Role module for X

{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let

  roleName = "ROLENAME";

in
{

  options = {
    roles.${roleName}.enable = lib.mkEnableOption "enables ${roleName} role";
  };

  config = lib.mkIf config.roles.${roleName}.enable {

  };
}
