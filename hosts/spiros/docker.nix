{
  lib,
  config,
  inputs,
  outputs,
  ...
}:
{

  #sops.secrets = {
  #  "borg/diskyDocker-pass" = { };
  #  "borg/diskyDocker-priv" = { };
  #};

  users.users.dan = {
    extraGroups = lib.mkDefault [ "docker" ];
    linger = true; # stop docker containers shutting down after user logout https://discourse.nixos.org/t/docker-containers-dont-work-if-user-is-logged-out/26569
  };

  # Enable rootless docker daemon
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true; # sets DOCKER_HOST variable to the rootless Docker instance for normal users by default
    daemon.settings = {
      #    data-root = "/mnt/diskyDocker/data-root";
      live-restore = false; # stop system hanging on shutdown
      ipv6 = false;
      dns = [ "192.168.50.206" ];
    };
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
  };

  boot.kernelModules = [ "br_netfilter" ];

}
