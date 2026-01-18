# custom module for user configuration

{
  lib,
  config,
  secrets,
  ...
}:
let

  user = "dan";

in
{

  options = {
    roles.users.enable = lib.mkEnableOption "Enables custom users module";
  };

  config = lib.mkIf config.roles.users.enable {

    users = {
      mutableUsers = lib.mkDefault false;
      users."${user}" = {
        isNormalUser = lib.mkDefault true;
        initialHashedPassword = lib.mkDefault secrets.default-initialHashedPassword;
        extraGroups = lib.mkDefault [ "wheel" ];
        openssh.authorizedKeys.keys = secrets.authorizedKeys-list;
      };
    };

  };

}
