{
  lib,
  config,
  inputs,
  ...
}:
let

  roleName = "wazuh-agent";

in
{

  imports = [
    inputs.wazuh-agent.nixosModules.wazuh-agent
  ];

  options = {
    roles.${roleName}.enable = lib.mkEnableOption "enables ${roleName} role";
  };

  config = lib.mkIf config.roles.${roleName}.enable {

    services.wazuh-agent = {
      enable = true;
      managerIP = "dennis";
    };

  };
}
