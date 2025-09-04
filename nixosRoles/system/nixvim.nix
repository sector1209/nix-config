# custom module for nixvim

{
  lib,
  config,
  inputs,
  ...
}:
{

  options = {
    roles.nixvim.enable = lib.mkEnableOption "enables nixvim module";
  };

  imports = [
    inputs.nixvim.nixosModules.nixvim
  ];

  config = lib.mkIf config.roles.nixvim.enable {

    programs.nixvim = {
      enable = true;

      colorschemes.everforest.enable = true;

      opts = {
        number = true;
        relativenumber = true;

        shiftwidth = 2;
      };

      plugins = {
        lightline.enable = true;
        lsp-lines.enable = true;
        lsp-format.enable = true;
        telescope.enable = true;
        web-devicons.enable = true;
        #	treesitter.enable = true;

        lsp = {
          enable = true;
          servers = {
            nixd.enable = true;
            docker_compose_language_service.enable = true;
          };
        };

        cmp = {
          enable = true;
          settings = {
            autoEnableSources = true;
            sources = [
              { name = "nvim_lsp"; }
              { name = "path"; }
              { name = "buffer"; }
            ];
          };
        };

      };
      extraConfigLua = "vim.g.clipboard = 'osc52'\nvim.o.clipboard = 'unnamedplus'\nvim.o.expandtab = true";
    };
  };
}
