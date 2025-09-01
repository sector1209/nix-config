{
  config,
  #  myData,
  pkgs,
  lib,
  ...
}:
let
  beszelConfigFile = pkgs.writeTextFile {
    name = "beszel-config.yml";
    text = lib.generators.toYAML { } {
      systems = config.roles.services.beszel-hub.settings;
    };
  };
in
{
  options.roles.services.beszel-hub = {
    enable = lib.mkEnableOption "Enable beszel-hub service";
    settings = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
            };
            host = lib.mkOption {
              type = lib.types.str;
            };
            port = lib.mkOption {
              type = lib.types.port;
            };
          };
        }
      );
      default = [ ];
      description = "Configuration of bezsel hub";
    };
  };

  options.roles.services.beszel-agent = {
    enable = lib.mkEnableOption "Enable beszel-agent service";
    extraFilesystems = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra filesystems to monitor";
    };
  };

  config =
    lib.mkIf (config.roles.services.beszel-hub.enable || config.roles.services.beszel-agent.enable)
      {
        # Include private ssh key as secret
        #    sops.secrets = lib.mkIf config.roles.services.beszel-hub.enable {
        #      inherit (myData.ageModules) beszel-ssh-ec;
        #    };

        # Make sure the bezsel hub home directory exists
        systemd.tmpfiles.rules = lib.mkIf config.roles.services.beszel-hub.enable [
          "d /var/lib/beszel-hub/beszel_data 0700 root root -"
        ];

        # Enable the beszel hub
        systemd.services.beszel-hub = lib.mkIf config.roles.services.beszel-hub.enable {
          description = "Beszel Hub";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          restartTriggers = [
            "/var/lib/beszel-hub/beszel_data/config.yml"
            #        config.age.secrets.beszel-ssh-ec.path
          ];
          serviceConfig = {
            Type = "simple";
            Restart = "always";
            RestartSec = "3";
            User = "root";
            WorkingDirectory = "/var/lib/beszel-hub";
            ExecStartPre = "${pkgs.coreutils}/bin/ln -sf ${beszelConfigFile} /var/lib/beszel-hub/beszel_data/config.yml";
            ExecStart = "${pkgs.beszel}/bin/beszel-hub serve --http 0.0.0.0:6432";
          };
        };

        # Enable the beszel agent
        systemd.services.beszel-agent = lib.mkIf config.roles.services.beszel-agent.enable {
          description = "Beszel Agent";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            PORT = "45876";
            KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvG17Y1MVpWgcKOr5fVXu+mJvypHGLp1RM3EWy6N/CX";
            EXTRA_FILESYSTEMS = lib.concatStringsSep "," config.roles.services.beszel-agent.extraFilesystems;
            DOCKER_HOST = lib.mkIf config.virtualisation.docker.rootless.enable "unix:///run/user/${toString config.users.users.dan.uid}/docker.sock";
          };
          serviceConfig = {
            Type = "simple";
            Restart = "always";
            RestartSec = "3";
            User = "root";
            ExecStart = "${pkgs.beszel}/bin/beszel-agent";
          };
        };
      };
}
