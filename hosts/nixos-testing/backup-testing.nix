# configuration for nixos-testing

{
  config,
  ...
}:
{

  sops.secrets = {
    "borg/test-pass" = { };
    "borg/test-priv" = { };
    "borg/gotify-token" = { };
  };

  #  roles.myBorgbackup.jobs.test = {
  #    repo = "borg@backupbox:.";
  #    passPath = toString "${config.sops.secrets."borg/test-pass".path}";
  #    keyPath = toString "${config.sops.secrets."borg/test-priv".path}";
  #    paths = "/home/dan/test-dir";
  #  };

  roles.myBorgbackup.jobs.test = {
    repo = "borg@backupbox:.";
    passPath = "${config.sops.secrets."borg/test-pass".path}";
    keyPath = "${config.sops.secrets."borg/test-priv".path}";
    paths = [ "/home/dan/backup-testdir" ];
    preHook = ''echo "Prehook command!!"'';
    postHook = ''echo "Posthook command!!!"'';
  };

}
