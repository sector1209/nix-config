{
  lib,
  config,
  secrets,
  ...
}:
let

  roleName = "git";

in
{

  options = {
    roles.${roleName}.enable = lib.mkEnableOption "enables ${roleName} role";
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    sops.secrets."keys/nix-config-repo-key" = {
      mode = "0600";
    };
    sops.secrets."keys/nix-secrets-repo-key" = {
      mode = "0600";
    };
    sops.secrets."keys/composes-repo-key" = {
      mode = "0600";
    };
    sops.secrets."keys/hugo-website-repo-key" = {
      mode = "0600";
    };
    sops.secrets."keys/nixos-dan-key" = {
      mode = "0600";
    };
    sops.secrets."keys/nixos-deploy-key" = {
    };

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
      enable = true;
      matchBlocks = {
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = [
            config.sops.secrets."keys/nix-config-repo-key".path
          ];
          extraOptions = {
            "PreferredAuthentications" = "publickey";
          };
        };
        "github.com-nix-secrets" = {
          hostname = "github.com";
          user = "git";
          identityFile = [
            config.sops.secrets."keys/nix-secrets-repo-key".path
          ];
          extraOptions = {
            "PreferredAuthentications" = "publickey";
          };
        };
        "github.com-composes" = lib.hm.dag.entryAfter [ "github.com-nix-secrets" ] {
          hostname = "github.com";
          user = "git";
          identityFile = [
            config.sops.secrets."keys/composes-repo-key".path
          ];
          extraOptions = {
            "PreferredAuthentications" = "publickey";
          };
        };
        "github.com-hugo-website" = lib.hm.dag.entryAfter [ "github.com-composes" ] {
          hostname = "github.com";
          user = "git";
          identityFile = [
            config.sops.secrets."keys/hugo-website-repo-key".path
          ];
          extraOptions = {
            "PreferredAuthentications" = "publickey";
          };
        };
        "dan" = lib.hm.dag.entryAfter [ "github.com-hugo-website" ] {
          match = "user dan";
          hostname = "%h";
          user = "dan";
          identityFile = [
            config.sops.secrets."keys/nixos-dan-key".path
          ];
          extraOptions = {
            "PreferredAuthentications" = "publickey";
            "AddKeysToAgent" = "yes";
          };
        };
        "deploy" = lib.hm.dag.entryAfter [ "github.com-hugo-website" ] {
          match = "user deploy";
          hostname = "%h";
          user = "deploy";
          identityFile = [
            config.sops.secrets."keys/nixos-deploy-key".path
          ];
          extraOptions = {
            "PreferredAuthentications" = "publickey";
            "AddKeysToAgent" = "yes";
            "ForwardAgent" = "yes";
          };
        };
      };
    };

    # Nicely reload system units when changing configs
    systemd.user.startServices = "sd-switch";

  };
}
