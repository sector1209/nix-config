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

  };
}
