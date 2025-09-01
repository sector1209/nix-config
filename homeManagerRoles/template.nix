# custom module for X

{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let

  configName = "SERVICENAME";

in
{

  options = {
    ${configName}.enable = lib.mkEnableOption "enables ${configName} module";
  };

  config = lib.mkIf config.${configName}.enable {

  };
}
