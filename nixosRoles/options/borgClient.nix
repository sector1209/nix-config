# custom defaults override for borgbackup clients

{ lib, config, ... }:

let

  mkBackupJobs =
    name: cfg:
    lib.nameValuePair name {

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
      postHook = ''
        	# User-defined postHook commands (run first)
        	${cfg.postHook}

        	# Always send Gotify notifications
        	export token="$(<${config.sops.secrets."borg/gotify-token".path})"
        	#echo "$token"

        	if [[ "$exitStatus" == 0 ]]; then
        	  /run/current-system/sw/bin/curl -X POST "https://gotify.danmail.me/message?token=''${token}" -F "title=${name} backup succeeded" -F "message=${name} backup succeeded";
        	else
        	  /run/current-system/sw/bin/curl -X POST "https://gotify.danmail.me/message?token=''${token}" -F "title=${name} backup failed" -F "message=${name} backup failed";
        	fi
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

    sops.secrets."borg/gotify-token" = { };

    services.borgbackup.jobs = lib.mapAttrs' mkBackupJobs config.roles.myBorgbackup.jobs;

  };

}
