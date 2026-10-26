# custom module for proxmox containers

{
  lib,
  config,
  modulesPath,
  ...
}:
{

  # Options for proxmox-lxc found here:
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/virtualisation/proxmox-lxc.nix
  imports = [ (modulesPath + "/virtualisation/proxmox-lxc.nix") ];

  options = {
    roles.proxmoxContainer = {

      enable = lib.mkEnableOption "enables proxmox container module";

      privilaged = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config =
    let
      cfg = config.roles.proxmoxContainer;
    in
    {

      proxmoxLXC = {
        enable = cfg.enable;
        manageNetwork = !cfg.enable;
        manageHostName = cfg.enable;
        privileged = cfg.privilaged;
      };

      networking.hostName = lib.mkIf config.proxmoxLXC.manageHostName (
        lib.mkOverride 500 (lib.strings.removeSuffix "\n" (builtins.readFile /etc/hostname))
      );

    };
}
