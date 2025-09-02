# custom module for X

{
  pkgs,
  lib,
  config,
  ...
}:
let

  configName = "flakeAutoUpdateSvr";

in
{

  options = {
    roles.${configName}.enable = lib.mkEnableOption "enables flake auto update server module";
  };

  config = lib.mkIf config.roles.${configName}.enable {

    systemd.services.flake-auto-update-svr = {
      enable = true;
      startAt = "daily";
      path = [
        pkgs.coreutils
        pkgs.git
        pkgs.nix
      ];
      serviceConfig = {
        User = "dan";
        ExecStart = "/run/current-system/sw/bin/sh ${pkgs.writeShellScript "start-flake-auto-update-svr" ''
          cd /nixos-configs
          git stash auto-flake-input-update
          nix flake update
          git add flake.lock
          git commit -m "flake.lock update"
          git stash pop auto-flake-input-update
        ''}";
      };
    };

  };
}
