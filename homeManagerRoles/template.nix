# custom module for X

{
  lib,
  config,
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
