# custom module for ssh

{
  pkgs,
  lib,
  config,
  ...
}:
{

  options = {
    roles.ssh.enable = lib.mkEnableOption "enables ssh module";
  };

  config = lib.mkIf config.roles.ssh.enable {

    programs.ssh.startAgent = true;

    # Enable the OpenSSH daemon
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        # PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password"; # see below
        UseDns = true; # trying to solve dennis' ssh woes
        StrictModes = false; # see above
        LogLevel = "DEBUG"; # above x2
      };
      authorizedKeysInHomedir = true; # again, trying to fix
    };

  };

}
