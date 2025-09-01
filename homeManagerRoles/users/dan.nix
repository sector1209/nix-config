{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{

  # TODO: Set your username
  home = {
    username = "dan";
    homeDirectory = "/home/dan";
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  # home.packages = with pkgs; [ steam ];

  # Enable home-manager and git
  programs.home-manager.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";
}
