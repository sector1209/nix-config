{
  lib,
  config,
  ...
}:
{

  sops.secrets."keys/nix-config-repo-key" = {
    mode = "0600";
  };
  sops.secrets."keys/composes-repo-key" = {
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
    userName = "Sector1209";
    userEmail = "gh@danmail.me";
    extraConfig = {
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
      "github.com-composes" = lib.hm.dag.entryAfter [ "github.com" ] {
        hostname = "github.com";
        user = "git";
        identityFile = [
          config.sops.secrets."keys/composes-repo-key".path
        ];
        extraOptions = {
          "PreferredAuthentications" = "publickey";
        };
      };
      "dan" = lib.hm.dag.entryAfter [ "github.com-composes" ] {
        match = ''user dan'';
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
      "deploy" = lib.hm.dag.entryAfter [ "github.com-composes" ] {
        match = ''user deploy'';
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

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";
}
