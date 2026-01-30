{
  lib,
  config,
  ...
}:
let

  roleName = "ssh";

in
{

  options = {
    roles.${roleName}.enable = lib.mkEnableOption "enables ${roleName} role";
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    sops.secrets."keys/nixos-dan-key" = {
      mode = "0600";
    };
    sops.secrets."keys/nixos-deploy-key" = {
      mode = "0600";
    };

    # Configure authentication for git repos
    programs.ssh = {
      enable = true;
      matchBlocks = {
        "dan" = lib.hm.dag.entryBefore [ "deploy" ] {
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
        "deploy" = lib.hm.dag.entryAnywhere {
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

  };

}
