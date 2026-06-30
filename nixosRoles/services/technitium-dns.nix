# custom module for ssh

{ lib, config, ... }:
let

  roleName = "technitium-dns";
  cfg = config.roles.technitium-dns;

in
{

  options = {
    roles.${roleName} = {
      enable = lib.mkEnableOption "enables ${roleName} module";
      hostName = lib.mkOption {
        type = lib.types.str;
      };
    };
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    sops.secrets = {
      "borg/techDns-pass" = { };
      "borg/techDns-priv" = { };
    };

    roles.myBorgbackup.jobs.techDns = lib.mkIf (config.networking.hostName == "technitium-dns") {
      repo = "borg@backupbox:.";
      paths = [ "/var/lib/technitium-dns-server" ];
      passPath = "${config.sops.secrets."borg/techDns-pass".path}";
      keyPath = "${config.sops.secrets."borg/techDns-priv".path}";
    };

    # Enable and configure technitium-dns-server
    services.technitium-dns-server = {
      enable = true;
      openFirewall = true;
    };

    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [
        80
        443
      ];
    };

    services.nginx = {
      virtualHosts = {
        "${cfg.hostName}.danmail.me" = {
          enableACME = true;
          acmeRoot = null; # i think this makes it use DNS-01 validation
          addSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:5380";
          };
        };
      };
    };

    roles.nginx.enable = true;

    # Override the upstream technitium-dns-server systemd unit
    systemd.services.technitium-dns-server.serviceConfig = lib.mkIf config.preservation.enable {
      # DynamicUser creates a temporary UID each boot and moves StateDirectory
      # to /var/lib/private/, making it impossible to persist correctly.
      # A static user sidesteps this entirely.
      DynamicUser = lib.mkForce false;
      User = "technitium-dns-server";
      Group = "technitium-dns-server";

      # Tells systemd to create /var/log/technitium and chown it to the service
      # user before the process starts. Without this, the app tries to create it
      # itself and hits ProtectSystem=strict.
      LogsDirectory = "technitium";

      # ProtectSystem=strict remounts /var (and /usr, /boot) read-only for the
      # service. This punches a specific hole to allow writes to the log directory
      # without disabling the hardening entirely.
      ReadWritePaths = [ "/var/log/technitium" ];
    };

    # Static user/group to replace DynamicUser.
    users.users.technitium-dns-server = lib.mkIf config.preservation.enable {
      isSystemUser = true;
      group = "technitium-dns-server";
    };
    users.groups.technitium-dns-server = lib.mkIf config.preservation.enable { };

    preservation.preserveAt."/persist".directories = lib.mkIf config.preservation.enable [
      {
        directory = "/var/lib/technitium-dns-server";
        user = "technitium-dns-server";
        group = "technitium-dns-server";
        mode = "0700";
      }
      {
        directory = "/var/log/technitium";
        user = "technitium-dns-server";
        group = "technitium-dns-server";
        mode = "0755";
      }
    ];
  };
}
