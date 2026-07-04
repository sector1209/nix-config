# custom module for nixvim

{
  lib,
  pkgs,
  config,
  ...
}:
{

  options = {
    roles.nixvim.enable = lib.mkEnableOption "enables nixvim module";
  };

  config = lib.mkIf config.roles.nixvim.enable {

    programs.nixvim = {
      enable = true;
      defaultEditor = lib.mkDefault true;

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
            nixd = {
              enable = true;
              settings = {
                formatting.command = [ "nixfmt" ];
                nixpkgs.expr = ''
                  let h = builtins.replaceStrings ["\n"] [""] (builtins.readFile /etc/hostname);
                  in (builtins.getFlake (builtins.toString ./.)).nixosConfigurations.''${h}.pkgs
                '';
                options = {
                  nixos.expr = ''
                    let h = builtins.replaceStrings ["\n"] [""] (builtins.readFile /etc/hostname);
                    in (builtins.getFlake (builtins.toString ./.)).nixosConfigurations.''${h}.options
                  '';
                  home_manager.expr = ''
                    let h = builtins.replaceStrings ["\n"] [""] (builtins.readFile /etc/hostname);
                    in (builtins.getFlake (builtins.toString ./.)).nixosConfigurations.''${h}.options.home-manager.users.type.getSubOptions []
                  '';
                };
              };
            };
            docker_compose_language_service.enable = (
              config.virtualisation.docker.enable || config.virtualisation.docker.rootless.enable
            );
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
    environment.systemPackages = [ pkgs.nixd ];
  };
}
