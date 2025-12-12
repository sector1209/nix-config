{ config, pkgs, ... }:
{

  # Install Hugo package to build site
  environment.systemPackages = with pkgs; [
    hugo
  ];

  users.groups.blog = {
    name = "blog";
    members = [
      "caddy"
      "dan"
    ];
  };

  # Define directories to persist between reboots
  environment.persistence."/persist/system" = {
    directories = [
      {
        directory = "/var/lib/www";
        user = "caddy";
        group = "blog";
        mode = "u=rwx,g=rwx,o=";
      }
    ];
  };

  roles.acme.enable = true;

  security.acme.defaults.reloadServices = [ "caddy.service" ];

  # ACME service for SSL certificate
  security.acme = {
    certs."blog.danmail.me" = {
      group = config.services.caddy.group;
    };
  };

  # Reverse proxy to static site
  services.caddy = {
    enable = true;
    virtualHosts."blog.danmail.me" = {
      extraConfig = ''
        root * /var/lib/www/hugo-website/public
        encode zstd gzip
        file_server
        tls /var/lib/acme/blog.danmail.me/cert.pem /var/lib/acme/blog.danmail.me/key.pem
      '';
    };
  };

}
