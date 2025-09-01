{
  writeShellApplication,
  jujutsu,
  pre-commit,
  jq,
  openssh,
  nix-output-monitor,
}:
writeShellApplication {
  name = "rebuild-remote";
  runtimeInputs = [
    jujutsu
    pre-commit
    jq
    openssh
    nix-output-monitor
  ];
  text = builtins.readFile ./rebuild-remote.sh;
}
