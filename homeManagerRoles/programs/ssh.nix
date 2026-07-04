{
  lib,
  config,
  osConfig,
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

    roles.sops.enable = true;

    sops.secrets =
      lib.mkIf
        (
          osConfig.roles.deployMachine.enable
          && (osConfig.roles.deployMachine.devUser == config.home.username)
        )
        {
          "keys/nixos-dan-key" = {
            mode = "0600";
          };
          "keys/nixos-deploy-key" = {
            mode = "0600";
          };
        };

    # Configure authentication for git repos
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        # Default config
        "*" = {
          ForwardAgent = false;
          AddKeysToAgent = "no";
          Compression = false;
          ServerAliveInterval = 0;
          ServerAliveCountMax = 3;
          HashKnownHosts = false;
          UserKnownHostsFile = "~/.ssh/known_hosts";
          ControlMaster = "no";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "no";
        };
      }
      //
        lib.optionalAttrs
          (
            osConfig.roles.deployMachine.enable
            && (osConfig.roles.deployMachine.devUser == config.home.username)
          )
          {
            "dan" = lib.hm.dag.entryBefore [ "deploy" ] {
              header = "Match user dan";
              HostName = "%h";
              User = "dan";
              IdentityFile = [
                config.sops.secrets."keys/nixos-dan-key".path
              ];
              PreferredAuthentications = "publickey";
              AddKeysToAgent = "yes";
            };
            "deploy" = lib.hm.dag.entryAnywhere {
              header = "Match user deploy";
              HostName = "%h";
              User = "deploy";
              IdentityFile = [
                config.sops.secrets."keys/nixos-deploy-key".path
              ];
              PreferredAuthentications = "publickey";
              AddKeysToAgent = "yes";
              ForwardAgent = "yes";
            };
          };
    };

  };

}
