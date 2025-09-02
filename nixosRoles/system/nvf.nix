# custom module for nvf

{
  lib,
  config,
  inputs,
  ...
}:
{

  options = {
    roles.nvf.enable = lib.mkEnableOption "enables nvf module";
  };

  imports = [
    inputs.nvf.nixosModules.default
  ];

  config = lib.mkIf config.roles.nvf.enable {

    programs.nvf = {
      enable = true;

      settings = {
        vim = {
          theme = {
            enable = true;
            name = "nord";
            style = "dark";
            transparent = true;
          };
          statusline.lualine.enable = true;
          telescope.enable = true;
          autocomplete.nvim-cmp.enable = true;

          languages = {
            enableLSP = true;
            enableTreesitter = true;

            nix.enable = true;
          };
        };
      };

    };

  };
}
