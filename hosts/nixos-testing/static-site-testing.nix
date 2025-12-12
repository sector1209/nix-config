{ pkgs, ... }:
{

  # Group for nginx and hugo deployer (dan)
  # users.groups.hugo-website.members = [
  #   "dan"
  #   "nginx"
  # ];

  # Install Hugo package to build site
  environment.systemPackages = with pkgs; [
    hugo
  ];

  # Enable Nginx role for default configurations
  roles.nginx.enable = true;

  # Reverse proxy to static site
  services.nginx = {
    enable = true;
    virtualHosts."blog.danmail.me" = {
      enableACME = true;
      acmeRoot = null;
      addSSL = true;
      root = "/var/lib/www/public/";
      extraConfig = ''
        index index.html;
      '';
      locations."/".tryFiles = "$uri $uri/ =404";
    };
  };

  # Open firewall for connections to site (eventually over Tailnet)
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # Systemd service to sync repo and rebuild site (?)
}
