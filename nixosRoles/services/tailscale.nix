# custom module for Tailscale service

{
  pkgs,
  lib,
  config,
  modulesPath,
  inputs,
  outputs,
  ...
}:
{

  options = {
    roles.tailscale.enable = lib.mkEnableOption "enables tailscale module";
  };

  config = lib.mkIf config.roles.tailscale.enable {

    sops.secrets."tailscale/nixos-deploy" = {
      #      owner = config.users.users.tailscale.name;
    };

    networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];

    # Enable the Tailscale daemon and point to authkey file
    services.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets."tailscale/nixos-deploy".path;
      extraUpFlags = [
        "--operator=dan"
      ];
      openFirewall = true;
    };

  };
}
