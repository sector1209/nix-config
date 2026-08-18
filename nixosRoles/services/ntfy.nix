# Role module for NTFY

{
  lib,
  config,
  secrets,
  ...
}:
let

  roleName = "ntfy";

in
{

  options = {
    roles.${roleName}.enable = lib.mkEnableOption "enables ${roleName} role";
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    sops.secrets = {
      "ntfy/user-pass-hash-publisher" = { };
      "ntfy/user-pass-hash-dan" = { };
    };

    sops.templates.ntfy-envFile = {
      content = lib.concatStrings [
        "NTFY_AUTH_USERS='"
        "dan:${config.sops.placeholder."ntfy/user-pass-hash-dan"}:user"
        ","
        "publisher:${config.sops.placeholder."ntfy/user-pass-hash-publisher"}:user"
        "'"
      ];
      owner = config.services.ntfy-sh.user;
    };

    services.ntfy-sh = {
      enable = true;
      environmentFile = "${config.sops.templates.ntfy-envFile.path}";
      settings = {
        # Server
        base-url = "https://ntfy${secrets.domain-name}";
        behind-proxy = true;
        listen-http = ":2586";
        # Access control
        auth-file = "/var/lib/ntfy-sh/auth.db";
        auth-default-access = "deny-all";
        auth-access = [
          "dan:*:read-only"
          "publisher:*:write-only"
        ];
        enable-login = true;
        require-login = true;
        enable-signup = false;
        # Attachments
        attachment-cache-dir = "/var/cache/ntfy-sh/attachments";
        # Message cache
        cache-file = "/var/cache/ntfy-sh/cache.db";
      };
    };

    systemd.services.ntfy-sh.serviceConfig.CacheDirectory = "ntfy-sh";

    roles.nginx.enable = true;

    services.nginx.virtualHosts."ntfy${secrets.domain-name}" = {
      enableACME = true;
      acmeRoot = null;
      addSSL = true;
      locations."/" = {
        proxyPass = "http://localhost${config.services.ntfy-sh.settings.listen-http}";
        proxyWebsockets = true;
      };
    };

    preservation.preserveAt."/persist".directories = [
      "/var/lib/ntfy-sh" # Probably will not work with DynamicUser
      "${config.services.ntfy-sh.settings.attachment-cache-dir}" # Probably will not work with DynamicUser
      "${config.services.ntfy-sh.settings.cache-file}" # Probably will not work with DynamicUser
    ];

  };
}
