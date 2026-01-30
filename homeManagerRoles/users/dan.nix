{
  ...
}:
{

  # Set username and home directory
  home = {
    username = "dan";
    homeDirectory = "/home/dan";
  };

  # Enable home-manager
  programs.home-manager.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  #home.stateVersion = "24.11";
}
