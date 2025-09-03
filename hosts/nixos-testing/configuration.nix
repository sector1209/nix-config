# configuration for nixos-testing

{
  ...
}:
let

  hostname = "nixos-testing";

in
{

  imports = [
    ./hardware-configuration.nix
    ./backup-testing.nix
  ];

  networking.hostName = hostname;

  roles = {

    proxmoxContainer.enable = true;

    deployMachine.enable = true;

    flakeLockAutoUpdate.enable = true;

    services.beszel-agent.enable = true;

    vscode-server.enable = true;

    prometheus-exporter.enable = true;

    promtail.enable = true;

  };

  system.stateVersion = "24.11";

}
