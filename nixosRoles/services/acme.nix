# Role module for ACME

{ lib, config, ... }:
let

  roleName = "acme";

in
{

  options = {
    roles.${roleName}.enable = lib.mkEnableOption "enables ${roleName} role";
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    sops.secrets = {
      porkbun-api-key = { };
      porkbun-secret-api-key = { };
    };

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "admin+acme@danmail.me";
        dnsProvider = "porkbun";
        credentialFiles = {
          "PORKBUN_API_KEY_FILE" = config.sops.secrets.porkbun-api-key.path;
          "PORKBUN_SECRET_API_KEY_FILE" = config.sops.secrets.porkbun-secret-api-key.path;
        };
        dnsResolver = "maceio.ns.porkbun.com";
      };
    };

  };
}
