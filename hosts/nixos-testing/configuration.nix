# configuration for nixos-testing

{
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
    ./backup-testing.nix
  ];

  roles = {

    proxmoxContainer.enable = true;

    deployMachine.enable = true;

    vscode-server.enable = true;

    prometheus-exporter.enable = true;

  };

  system.stateVersion = "24.11";

}
