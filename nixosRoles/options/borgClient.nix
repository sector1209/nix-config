# custom defaults override for borgbackup clients

{
  lib,
  config,
  pkgs,
  secrets,
  ...
}:

let

  mkBackupJobs =
    jobName: cfg:
    lib.nameValuePair jobName {

      repo = "${cfg.repo}";
      paths = cfg.paths;
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${cfg.passPath}";
      };
      environment = {
        BORG_RSH = "ssh -i ${cfg.keyPath}";
      };
      compression = "auto,zstd";
      prune.keep = {
        within = "1d"; # Keep all archives from the last day
        daily = 7;
        weekly = 4;
        monthly = -1; # Keep at least one archive for each month
      };
      preHook = "${cfg.preHook}";
      postHook =
        let
          hostName = config.networking.hostName;
        in
        ''
          	# User-defined postHook commands (run first)
          	${cfg.postHook}

          	# Always send notifications
          	if [[ "$exitStatus" == 0 ]]; then

             title="[${hostName}] Backup SUCCESS (${jobName})"
             priority="low"
             tags="floppy_disk,heavy_check_mark"
             body="Host: ${hostName}
           Job: ${jobName}
           Status: SUCCESS
           Archive: $archiveName
           Time: $(date -Is)"

           else

             title="[${hostName}] Backup FAILED (${jobName})"
             priority="default"
             tags="floppy_disk,x"
             body="Host: ${hostName}
           Job: ${jobName}
           Status: FAILED
           Exit code: $exitStatus
           Time: $(date -Is)
           Check: journalctl -u borgbackup-job-${jobName}.service"

           fi

           ${pkgs.curl}/bin/curl -sf \
             -H "Title: $title" \
             -H "Priority: $priority" \
             -H "Tags: $tags" \
             -H "Authorization: Bearer $(cat ${config.sops.secrets."borg/ntfy-token".path})" \
             -d "$body" \
             https://ntfy${secrets.domain-name}/borgbackup
        '';

    };

  jobModule =
    { lib, ... }:
    {

      options = {

        repo = lib.mkOption {
          type = lib.types.str;
          default = "borg@backupbox:.";
        };

        paths = lib.mkOption {
          type = lib.types.listOf lib.types.str;
        };

        passPath = lib.mkOption {
          type = lib.types.str;
        };

        keyPath = lib.mkOption {
          type = lib.types.str;
        };

        preHook = lib.mkOption {
          type = lib.types.lines;
          default = "";
        };

        postHook = lib.mkOption {
          type = lib.types.lines;
          default = "";
        };

      };

    };

in
{

  options = {

    roles.myBorgbackup.jobs = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (lib.types.submodule jobModule);
    };

  };

  config = lib.mkIf (config.roles.myBorgbackup.jobs != { }) {

    sops.secrets."borg/ntfy-token" = { };

    services.borgbackup.jobs = lib.mapAttrs' mkBackupJobs config.roles.myBorgbackup.jobs;

  };

}
