# Default module that imports all custom modules

{
  modulesPath,
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  ...
}:
let

in
{

  imports = [
    ### System related roles ###
    #    ./common.nix
    ./system/deployUser.nix
    ./system/sops.nix
    ./system/proxmoxContainer.nix
    ./system/containerSettings.nix
    ./system/vmSettings.nix
    ./system/flakeSettings.nix
    ./system/qsv.nix
    ./system/updateSettings.nix
    ./system/localisation.nix
    ./system/packages.nix
    ./system/users.nix
    ./system/networking.nix
    ./system/aliases.nix
    ./system/zsh.nix
    ./system/fish.nix
    #    ./system/nvf.nix
    ./system/nixvim.nix
    ./system/fonts.nix
    ./system/deployMachine.nix
    ./system/impermanence.nix
    ### Service related roles ###
    ./services/acme.nix
    ./services/jellyfin.nix
    ./services/ssh.nix
    ./services/tailscale.nix
    ./services/docker.nix
    ./services/technitium-dns.nix
    ./services/glances.nix
    ./services/nginx.nix
    ./services/nextcloud.nix
    ./services/gotify.nix
    ./services/immich.nix
    ./services/borgbackupServer.nix
    ./services/flakeAutoUpdateSvr.nix
    ./services/beszel.nix
    ./services/vscode-server.nix
    ./services/prometheus-exporter.nix
    ./services/promtail.nix
    ./services/influxdb.nix
    ./services/grafanaStack.nix
    ### More complex custom roles ###
    ./options/borgClient.nix
  ];

  roles = {

    sops.enable = lib.mkDefault true;

    flakeSettings.enable = lib.mkDefault true;

    updateSettings.enable = lib.mkDefault true;

    localisation.enable = lib.mkDefault true;

    packages.enable = lib.mkDefault true;

    networking.enable = lib.mkDefault true;

    users.enable = lib.mkDefault true;

    aliases.enable = lib.mkDefault true;

    fonts.enable = lib.mkDefault true;

    #  nvf.enable =
    #    lib.mkDefault true;

    # Disabled as causing nodejs_18 issues with nixpkgs 25.05
    nixvim.enable = lib.mkDefault true;

    fish.enable = lib.mkDefault true;

    ssh.enable = lib.mkDefault true;

    tailscale.enable = lib.mkDefault true;

    deployUser.enable = lib.mkDefault true;

    prometheus-exporter.enable = lib.mkDefault true;

    promtail.enable = lib.mkDefault true;

  };

  documentation.nixos.enable = true;

}
