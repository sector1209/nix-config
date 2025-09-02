# Role module for vscode-server

{
  lib,
  config,
  inputs,
  ...
}:
let

  roleName = "vscode-server";

in
{

  imports = [
    inputs.vscode-server.nixosModules.default
  ];

  options = {
    roles.${roleName}.enable = lib.mkEnableOption "enables ${roleName} role";
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    services.vscode-server.enable = true;

  };
}
