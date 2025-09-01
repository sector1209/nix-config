# custom module for proxmox containers

{
  pkgs,
  lib,
  config,
  modulesPath,
  inputs,
  outputs,
  ...
}:
{

  imports = [ (modulesPath + "/virtualisation/proxmox-lxc.nix") ]; # Options for proxmox-lxc found here: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/virtualisation/proxmox-lxc.nix

  options = {
    roles.proxmoxContainer = {

      enable = lib.mkEnableOption "enables proxmox container module";

      privilaged = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config = {

    proxmoxLXC = {
      enable = config.roles.proxmoxContainer.enable;
      manageNetwork = lib.mkIf config.roles.proxmoxContainer.enable false;
      manageHostName = lib.mkIf config.roles.proxmoxContainer.enable true;
      privileged = config.roles.proxmoxContainer.privilaged;

    };

    networking.hostName = lib.mkIf config.proxmoxLXC.manageHostName (
      lib.mkOverride 500 (lib.strings.removeSuffix "\n" (builtins.readFile /etc/hostname))
    );

  };
}
