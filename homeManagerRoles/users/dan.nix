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

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
