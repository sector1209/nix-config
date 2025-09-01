# custom module for Proxmox containers

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

  #  imports = [
  #  # Include the default lxc/lxd configuration.
  #  "${modulesPath}/virtualisation/lxc-container.nix"
  #  ];

  options = {
    roles.containerSettings.enable = lib.mkEnableOption "Enables custom LXC container settings module";
  };

  config = lib.mkIf config.roles.containerSettings.enable {

    #    import = [
    #      # Include the default lxc/lxd configuration.
    #      "${modulesPath}/virtualisation/lxc-container.nix"
    #    ];

    boot.isContainer = true;

    # Supress systemd units that don't work because of LXC.
    # https://blog.xirion.net/posts/nixos-proxmox-lxc/#configurationnix-tweak
    systemd.suppressedSystemUnits = [
      "dev-mqueue.mount"
      "sys-kernel-debug.mount"
      "sys-fs-fuse-connections.mount"
    ];

  };

}
