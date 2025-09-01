# custom module for fish configuration

{
  pkgs,
  lib,
  config,
  ...
}:
{

  options = {
    roles.fish.enable = lib.mkEnableOption "enables fish module";
  };

  config = lib.mkIf config.roles.fish.enable {

    programs = {
      fish.enable = true;
    };

    # Set bash to change to fish on login
    programs.bash = {
      interactiveShellInit = ''
        	if [[ "$(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm)" != "fish" && -z "''${BASH_EXECUTION_STRING}" ]]
        	then
        	  shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        	  exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
        	fi
      '';
    };

  };
}
