# custom module

{
  pkgs,
  lib,
  config,
  ...
}:
{

  options = {
    roles.packages.enable = lib.mkEnableOption "enables packages module";
  };

  config = lib.mkIf config.roles.packages.enable {
    environment.systemPackages = with pkgs; [
      vim
      neovim
      dig
      # gitFull includes libsecret
      gitFull
      man
      tmux
      home-manager
      lsof
      nvd
      rsync
      bat
      htop
    ];

    programs = {
      nix-ld.enable = true;
    };

    # Set neovim as the default editor
    programs.neovim = {
      enable = lib.mkForce true;
      defaultEditor = lib.mkForce true;
    };

  };
}
