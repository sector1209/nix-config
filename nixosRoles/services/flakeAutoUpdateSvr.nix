# custom module for a systemd service to automatically update flake.lock

{
  pkgs,
  lib,
  config,
  ...
}:
let

  configName = "flakeLockAutoUpdate";

in
{

  options = {
    roles.${configName}.enable = lib.mkEnableOption "enables flake.lock auto update service";
  };

  config = lib.mkIf config.roles.${configName}.enable {

    systemd.services.flake-lock-auto-update = {
      enable = true;
      startAt = "daily";
      path = [
        pkgs.coreutils
        pkgs.git
        pkgs.nix
      ];
      serviceConfig = {
        User = "dan";
        ExecStart = "/run/current-system/sw/bin/sh ${pkgs.writeShellScript "start-flake-lock-auto-update" ''
          # Change directory
          cd /nix-config

          # Save the current branch
          CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

          # Check if the "flake-lock-update" branch exists
          if ! git show-ref --verify --quiet refs/heads/flake-lock-update; then
            echo "The branch 'flake-lock-update' does not exist."
            exit 1
          fi

          # Stash changes on working branch
          git stash push --include-untracked -m "temp automatic flake.lock update stash"

          # Switch to the "flake-lock-update" branch
          git checkout flake-lock-update

          # Merge from main branch
          git merge main

          # Update flake inputs
          nix flake update
          git add flake.lock
          git commit -m "Automatic flake.lock update"

          # Switch back to the original branch
          git checkout "$CURRENT_BRANCH"
          echo "Switched back to branch: $CURRENT_BRANCH"

          git stash pop --index
        ''}";
      };
    };

  };
}
