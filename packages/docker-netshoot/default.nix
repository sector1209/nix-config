{
  writeShellApplication,
  docker,
}:
writeShellApplication {
  name = "docker-netshoot";
  runtimeInputs = [
    docker
  ];
  text = builtins.readFile ./docker-netshoot.sh;
}
