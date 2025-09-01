# custom module for funcTest service

{
  pkgs,
  lib,
  config,
  ...
}:
{

  config = lib.mkIf config.roles.funcTest.enable {

    sops.secrets = {
      "borg/techDns-pass" = { };
      "borg/techDns-priv" = { };
    };

    roles.myBorgbackup.jobs.techDns = {
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
        "dns.danmail.me" = {
          enableACME = true;
          acmeRoot = null; # i think this makes it use DNS-01 validation
          addSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:5380";
          };
        };
      };
    };

    nginx.enable = true;

  };
}
