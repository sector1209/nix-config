# custom module with localisation and timezone settings
{
  pkgs,
  lib,
  config,
  ...
}:
let

  timeZone = "Europe/London";
  defaultLocale = "en_GB.UTF-8";

in
{

  options = {
    roles.localisation.enable = lib.mkEnableOption "enables localisation module";
  };

  config = lib.mkIf config.roles.localisation.enable {

    time.timeZone = timeZone;

    i18n = {
      defaultLocale = defaultLocale;
      extraLocaleSettings = {
        LC_ADDRESS = defaultLocale;
        LC_IDENTIFICATION = defaultLocale;
        LC_MEASUREMENT = defaultLocale;
        LC_MONETARY = defaultLocale;
        LC_NAME = defaultLocale;
        LC_NUMERIC = defaultLocale;
        LC_PAPER = defaultLocale;
        LC_TELEPHONE = defaultLocale;
        LC_TIME = defaultLocale;
      };
    };

    environment.variables = {
      TZ = config.time.timeZone;
    };

  };
}
