# custom module for ssh

{
  lib,
  pkgs,
  config,
  ...
}:
{

  options = {
    roles.docker.enable = lib.mkEnableOption "enables docker module";
  };

  config = lib.mkIf config.roles.docker.enable {

    sops.secrets = {
      "borg/diskyDocker-pass" = { };
      "borg/diskyDocker-priv" = { };
    };

    roles.myBorgbackup.jobs.diskyDocker = {
      repo = "borg@backupbox:.";
      paths = [ "/mnt/diskyDocker" ];
      passPath = "${config.sops.secrets."borg/diskyDocker-pass".path}";
      keyPath = "${config.sops.secrets."borg/diskyDocker-priv".path}";
    };

    environment.systemPackages = [
      pkgs.docker-compose-language-service
    ];

    users.users.dan = {
      extraGroups = [ "docker" ];
      linger = true; # stop docker containers shutting down after user logout https://discourse.nixos.org/t/docker-containers-dont-work-if-user-is-logged-out/26569
    };

    # Enable rootless docker daemon
    virtualisation.docker.rootless = {
      enable = true;
      setSocketVariable = true; # sets DOCKER_HOST variable to the rootless Docker instance for normal users by default
      daemon.settings = {
        data-root = "/mnt/diskyDocker/data-root";
        live-restore = false; # stop system hanging on shutdown
        ipv6 = false;
        dns = [ "192.168.50.206" ];
        default-address-pools = [
          {
            base = "172.96.0.0/16";
            size = 24;
          }
        ];
      };
    };

    # Mount filesystem for docker-root
    fileSystems."/mnt/diskyDocker" = {
      device = "/dev/disk/by-uuid/c1e06b1f-61cc-44a1-a635-efab944ab79a";
      fsType = "ext4";
    };

    # Convenient shell aliases
    environment.shellAliases = {
      dc = "docker compose";
      dcupdate = "docker compose down && docker compose pull && docker compose up -d --force-recreate --remove-orphans";
      cdcompdir = "cd /mnt/diskyDocker/composes";
      caddyreload = "docker exec -it caddy caddy reload --config /etc/caddy/Caddyfile";
      gluetuntest = "docker run --rm --network=container:gluetun alpine:3.18 sh -c 'apk add wget && wget -qO- https://ipinfo.io'";
    };

    boot.kernel.sysctl = {
      "net.ipv4.ip_unprivileged_port_start" = 80; # allow docker to assign port 80 (under 1024) when running rootless
      "net.ipv4.ip_forward" = 1;
    };

    boot.kernelModules = [ "br_netfilter" ];

  };

}
