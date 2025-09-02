# custom module for user configuration

{
  lib,
  config,
  ...
}:
let

  user = "dan";

in
{

  options = {
    roles.users.enable = lib.mkEnableOption "Enables custom users module";
  };

  config = lib.mkIf config.roles.users.enable {

    users = {
      mutableUsers = lib.mkDefault false;
      users."${user}" = {
        isNormalUser = lib.mkDefault true;
        initialHashedPassword = lib.mkDefault "$y$j9T$8dwO5vaOgfoqjajP6P1o4.$GAXJl8bFxi.7dJxO7jElSCF3T2OmEo/IYDI1VlmHL.8";
        extraGroups = lib.mkDefault [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIInQa//eQdA7R3LWyccy3dyNqbjisirWiCaeymYc2C7l dan@danbook-pro.bee-atria.ts.net"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKXG07Mrar3L5LtjVQiO26Rs00lx4073dYGPMo3gcwVf danplus_id_ed25519"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF7iLoXoXsChx1KHnxh5IDCgnnRoLov6vl7fe6RqWdlB patrik_id_ed25519.pub"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL91ufGabBT6wyThCZ8prx/bcWh3+aeTeswp14sJNJd2 dan@nixos-testing"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILWbcgTPKaYp2JYNF/Dn/hD9NKZCGk6knd2e1mgZeaMU dan@ferb"
        ];
      };
    };

    # Enable passwordless sudo.
    security.sudo.wheelNeedsPassword = lib.mkDefault false;

    # Add user to 'trusted-users' group to make remote builds work (https://nixos.wiki/wiki/Nixos-rebuild)
    nix.settings.trusted-users = [ user ];

  };

}
