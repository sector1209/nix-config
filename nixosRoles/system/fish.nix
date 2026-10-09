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
      fish = {
        enable = true;
        interactiveShellInit = ''
          function fish_greeting
            # -- CAT ONE LINE TEXT --
            set_color --reset
            echo "  ∧,,,∧"
            echo " (• ⩊ •)" (set_color green)(whoami)(set_color --reset)"@"(set_color yellow)(hostname) (set_color --reset)"running on" (set_color blue)(awk -F'"' '/PRETTY_NAME/ {print $2}' /etc/os-release)
            echo (set_color yellow)" ￣"(set_color --reset)"U U"(set_color yellow)"￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣"
            echo (set_color cyan)" Memory" (set_color yellow)"-"  (set_color --reset)(free -h | awk '/Mem:/ { print $3" / "$2 }')
            echo (set_color cyan)" CPU   " (set_color yellow)"-"  (set_color --reset)(awk '/cpu cores/{c=1} c{ print $4; if (/cpu cores/) exit }' /proc/cpuinfo) "Cores," (uptime | awk '{ print substr($(NF-2), 1, length($(NF-2)) - 1)"% Load" }')
            echo (set_color cyan)" Disk  " (set_color yellow)"-"  (set_color --reset)(df -H / | awk '/dev/ { print $2" total, "$3" used" }')
            echo
          end
        '';
      };
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
