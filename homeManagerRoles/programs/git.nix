{
  lib,
  config,
  secrets,
  ...
}:
let

  roleName = "git";

  cfg = config.roles.git;

  mkSopsConfig = repo: {
    "keys/${repo}-repo-key" = {
      mode = "0600";
    };
  };

  sopsSecrets = lib.mergeAttrsList (map mkSopsConfig cfg.repos);

  mkMatchBlocks = repo: {
    header = "Host github.com-${repo}";
    HostName = "github.com";
    User = "git";
    IdentityFile = [
      config.sops.secrets."keys/${repo}-repo-key".path
    ];
    PreferredAuthentications = "publickey";
  };

  matchBlocks = lib.hm.dag.entriesBefore "git-repo" [ "dan" "deploy" ] (map mkMatchBlocks cfg.repos);

in
{

  options = {
    roles.${roleName} = {
      enable = lib.mkEnableOption "enables ${roleName} role";
      repos = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Git repos for which to enable SSH configuration.
        '';
      };
    };
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    roles = {
      sops.enable = true;
      ssh.enable = true;
    };

    # Enable and configure Git
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "Sector1209";
          email = secrets.gh-email;
        };
        pull = {
          rebase = true;
        };
        push = {
          autoSetupRemote = true;
        };
      };
    };

    sops.secrets = sopsSecrets;

    # Configure SSH authentication for Git repos
    programs.ssh.settings = matchBlocks;

  };
}
