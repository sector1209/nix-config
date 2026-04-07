# Role module for Beszel agent

{
  lib,
  config,
  ...
}:
let

  roleName = "beszel-agent";

in
{

  options = {
    roles.${roleName} = {
      enable = lib.mkEnableOption "enables ${roleName} role";
      extraFilesystems = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra filesystems to monitor";
      };
    };
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    sops.secrets = {
      beszel-env-file = {
        owner = config.users.users.beszel-agent.name;
      };
    };

    services.beszel.agent = {
      enable = true;
      openFirewall = true;
      environment = {
        PORT = "45876";
        EXTRA_FILESYSTEMS = lib.concatStringsSep "," config.roles.beszel-agent.extraFilesystems;
        DOCKER_HOST = lib.mkIf config.virtualisation.docker.rootless.enable "unix:///run/user/1001/docker.sock";
        HUB_URL = "https://beszel.danmail.me";
      };
      environmentFile = config.sops.secrets.beszel-env-file.path;
    };

  };
}
