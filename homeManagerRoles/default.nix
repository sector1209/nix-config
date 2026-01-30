# default  that pulls in all other home-manager config

{
  ...
}:
{

  imports = [
    #    ./home.nix
    ./programs/git.nix
    ./sops.nix
    ./users/dan.nix
  ];

}
