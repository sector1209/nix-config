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

  sopsSecrets = lib.mergeAttrsList (builtins.map mkSopsConfig cfg.repos);

  mkMatchBlocks = repo: {
    "github.com-${repo}" = lib.hm.dag.entryBefore [ "dan" ] {
      HostName = "github.com";
      User = "git";
      IdentityFile = [
        config.sops.secrets."keys/${repo}-repo-key".path
      ];
      PreferredAuthentications = "publickey";
    };
  };

  matchBlocks = lib.mergeAttrsList (builtins.map mkMatchBlocks cfg.repos);

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

    sops.secrets = sopsSecrets;

    # Enable and configure git
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

    # Configure authentication for git repos
    programs.ssh = {
      settings = matchBlocks;
    };

  };
}
