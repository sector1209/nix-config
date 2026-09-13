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

  roles.myBorgbackup.jobs.test = {
    passPath = "${config.sops.secrets."borg/test-pass".path}";
    keyPath = "${config.sops.secrets."borg/test-priv".path}";
    paths = [ "/home/dan/backup-testdir" ];
    # preHook = ''echo "Prehook command!!"'';
    # postHook = ''echo "Posthook command!!!"'';
  };

}
