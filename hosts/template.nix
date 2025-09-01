{
  modulesPath,
  config,
  pkgs,
  ...
}:
let

  hostname = "";

in
{

  imports = [
  ];

  networking.hostName = hostname;

}
