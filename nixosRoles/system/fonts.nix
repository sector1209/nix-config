# custom module for fonts

{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{

  options = {
    roles.fonts.enable = lib.mkEnableOption "enables fonts module";
  };

  config = lib.mkIf config.roles.fonts.enable {

    fonts = {
      packages = with pkgs; [
        comic-mono
      ];
      fontconfig = {
        enable = true;
        defaultFonts = {
          monospace = [ "comic-mono" ];
          serif = [ "comic-mono" ];
          sansSerif = [ "comic-mono" ];
        };
      };
    };
  };
}
