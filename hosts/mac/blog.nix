{
  config,
  pkgs,
  lib,
  ...
}:
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

  # Reverse proxies to static site
  services.caddy = {
    enable = true;
    # Reverse proxy to terminate TLS and pass to Anubis
    virtualHosts."blog.danmail.me" = {
      extraConfig = ''
        tls /var/lib/acme/blog.danmail.me/cert.pem /var/lib/acme/blog.danmail.me/key.pem
        reverse_proxy localhost:8081
      '';
    };
    # Reverse proxy to serve static blog site
    virtualHosts.":7000" = {
      extraConfig = ''
        root * /var/lib/www/hugo-website/public
        encode zstd gzip
        file_server
      '';
      logFormat = lib.mkForce ''
        output file ${config.services.caddy.logDir}/access-blog-backend.log
      '';
    };
  };

  services.anubis.instances.blog.settings = {
    BIND = ":8081";
    TARGET = "http://127.0.0.1:7000";
    BIND_NETWORK = "tcp";
    SERVE_ROBOTS_TXT = true;
  };

  # Systemd service to pull changes
  systemd.services.pull-blog-changes = {
    enable = true;
    startAt = "daily";
    path = [
      pkgs.coreutils
      pkgs.git
      pkgs.openssh
    ];
    serviceConfig = {
      User = "dan";
      ExecStart = "/run/current-system/sw/bin/sh ${pkgs.writeShellScript "pull-blog-changes" ''
        # Change directory
        cd /var/lib/www/hugo-website

        # Pull any changes from remote repo
        git pull
      ''}";
    };
  };

}
