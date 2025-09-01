{
  writeShellApplication,
  jujutsu,
  pre-commit,
  jq,
  nix-output-monitor,
}:
writeShellApplication {
  name = "rebuild";
  runtimeInputs = [
    jujutsu
    pre-commit
    jq
    nix-output-monitor
  ];
  text = builtins.readFile ./rebuild.sh;
}
