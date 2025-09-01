help_base="\
Usage: $(basename "${BASH_SOURCE[0]}") [subcommand]

Subcommands:
  one [HOST]	Update one remote host
  many		Update many remote hosts
"

help_one="\
Usage: $(basename "${BASH_SOURCE[0]}") <arguement> | [OPTIONS]

Options:
  -h, --help	Show this message and exit.
"

help_many="\
Usage: $(basename "${BASH_SOURCE[0]}") [OPTIONS]

Options:
  -i, --ignore	[HOSTS]
  -h, --help	Show this message and exit.
"

info() {
  echo -e "\033[94m$1\033[0m"
}
hint() {
  echo -e "\033[2;3m$1\033[0m"
}
success() {
  echo -e "\033[92m$1\033[0m"
}
warning() {
  echo -e "\033[93m$1\033[0m"
}
error() {
  echo -e "\033[91m$1\033[0m"
}

unexpected_error() {
  error "Unexpected error on line $1 (code $2)"
}
trap 'unexpected_error $LINENO $?' ERR

###

# TODO: replace error "echo"s with error "error message" function

# Define functions at the top of the script
do_pre-commit() {
  info "Autoformatting NixOS configuration ..."
  pre-commit run --all-files &> /dev/null || true
  pre-commit run --all-files | (grep -v "Passed" || true)
}

# TODO: Readd ${mode} option
do_rebuild() {
  local target="$1"
  # Get list of hosts in flake
  local flakeHosts=()

  # Make temp directory for logs
  local tmp
  tmp=$(mktemp -d) || {
    error "Failed to create temporary directory"
    exit 1
  }

  local logFile="$tmp/$target-rebuild.log"

  IFS=" " read -r -a flakeHosts <<< "$(nix eval .#nixosConfigurations --apply 'pkgs: builtins.concatStringsSep " " (builtins.attrNames pkgs)' | xargs)"

  # Check if target host is in the flake
  if [[ " ${flakeHosts[*]} " != *" ${target} "* ]]; then
    error "$target} not found in flake hosts"
    exit 1
  fi

  #    pushd /nixos-configs &> /dev/null

  local rsa_key
  rsa_key="$HOME/.config/sops-nix/secrets/keys/nixos-deploy-key"

  local initDir
  initDir=$(ssh -i "$rsa_key" "$target" "readlink /run/current-system")
  echo "$initDir"

  info "Building NixOS configuration ..."
  nixos-rebuild --log-format internal-json switch --flake ".#$target" --target-host "deploy@$target" --use-remote-sudo |&
    tee >(
      grep --line-buffered "@nix " |
        stdbuf -oL cut -c 6- |
        jq --unbuffered --raw-output 'select(.action == "msg").msg' > "$logFile"
    ) |&
    nom --json ||
    {
      error "Building NixOS failed with:"
      grep --color error -A 10 < "$logFile" || error "unknown error"
      hint "(check $logFile for the full build log)"
      popd &> /dev/null
      exit 1
    }

  ssh -i "$rsa_key" "$target" "nvd diff $initDir /run/current-system"
}

do_one() {
  local arg="$1"

  # Do pre-commit formatting
  do_pre-commit

  info "Rebuilding single host: $arg"
  do_rebuild "$arg"
}

do_many() {
  local ignore_list=("$@") # Get ignored hosts as array

  # Do pre-commit formatting
  do_pre-commit

  if [[ ${#ignore_list[@]} -gt 0 ]]; then
    echo "Ignoring hosts: ${ignore_list[*]}"
  fi

  # Get list of hosts in flake
  local flakeHosts=()
  IFS=" " read -r -a flakeHosts <<< "$(nix eval .#nixosConfigurations --apply 'pkgs: builtins.concatStringsSep " " (builtins.attrNames pkgs)' | xargs)"

  # Function to check if a host should be ignored
  should_ignore() {
    local host="$1"
    for ignored in "${ignore_list[@]}"; do
      if [[ $host == "$ignored" ]]; then
        return 0 # Should ignore
      fi
    done
    return 1 # Should not ignore
  }

  for host in "${flakeHosts[@]}"; do
    if should_ignore "$host"; then
      info "Skipping ignored host: $host"
    else
      info "Rebuilding host: $host"
      do_rebuild "$host"
    fi
  done
}

###

# Parse subcommand first
if [[ $# -eq 0 ]]; then
  echo "$help_base"
  exit 1
fi

subcommand="$1"
shift # Remove subcommand from arguments

case "$subcommand" in
  one)

    # Reset OPTIND for this subcommand's option parsing
    OPTIND=1

    # Handle one-specific options
    while [[ $OPTIND -le $# ]]; do
      if getopts ":-:" OPTCHAR; then
        if [[ $OPTCHAR == "-" ]]; then
          case "$OPTARG" in
            help)
              echo "$help_one"
              exit 0
              ;;
            *)
              warning "one: invalid option '--$OPTARG'"
              ;;
          esac
        else
          case "$OPTARG" in
            h)
              echo "$help_one"
              exit 0
              ;;
            *)
              warning "one: invalid option '-$OPTARG'"
              ;;
          esac
        fi
      else
        # Break when getops can't parse any more
        break
      fi
    done

    # Now get the required argument from remaining args
    # OPTIND points to the first non-option argument
    if [[ $OPTIND -gt $# ]]; then
      error "'one' subcommand requires an argument"
      echo "$help_one"
      exit 1
    fi

    one_arg="${!OPTIND}"

    # Execute the 'one' command
    do_one "$one_arg"
    ;;

  many)

    # Reset OPTIND for this subcommand's option parsing
    OPTIND=1
    ignore_list=() # Initialize empty array for ignored hosts

    # Handle many-specific options
    while [[ $OPTIND -le $# ]]; do
      if getopts ":-:" OPTCHAR; then
        if [[ $OPTCHAR == "-" ]]; then
          case "$OPTARG" in
            help)
              echo "$help_many"
              exit 0
              ;;
            ignore)
              # Handle --ignore with argument
              if [[ $OPTIND -le $# ]]; then
                ignore_hosts="${!OPTIND}"
                ((OPTIND++))
                # Split comma-separated list into array
                IFS=',' read -r -a ignore_list <<< "$ignore_hosts"
              else
                warning "many: --ignore requires an argument"
                exit 1
              fi
              ;;
            ignore=*)
              # Handle --ignore=hosts format
              ignore_hosts="${OPTARG#*=}"
              IFS=',' read -r -a ignore_list <<< "$ignore_hosts"
              ;;
            *)
              warning "many: invalid option '--$OPTARG'"
              ;;
          esac
        else
          case "$OPTARG" in
            h)
              echo "$help_many"
              exit 0
              ;;
            i)
              # Handle -i with argument
              if [[ $OPTIND -le $# ]]; then
                ignore_hosts="${!OPTIND}"
                ((OPTIND++))
                # Split comma-separated list into array
                IFS=',' read -r -a ignore_list <<< "$ignore_hosts"
              else
                warning "many: -i requires an argument"
                exit 1
              fi
              ;;
            *)
              warning "many: invalid option '-$OPTARG'"
              ;;
          esac
        fi
      fi
    done

    # Execute the 'many' command
    do_many "${ignore_list[@]}"
    ;;

  *)
    error "Unknown subcommand: $subcommand"
    echo "$help_base"
    exit 1
    ;;
esac

###

###

#if $update; then
#    info "Updating NixOS configuration ..."
#    nix flake update
#fi

#info "Autoformatting NixOS configuration ..."
#pre-commit run --all-files &> /dev/null || true
#pre-commit run --all-files | (grep -v "Passed" || true)

#echo
#info "Configuration changes:"
#changed_files=$(jj diff --summary --color always)
#if [[ $(wc -l <<< "$changed_files") -le 5 ]]; then
#    jj diff --no-pager
#else
#    echo "$changed_files"
#fi

##NIX_SYSTEM="/nix/var/nix/profiles/system"
##generation_number=$(readlink "$NIX_SYSTEM" | awk -F "-" '{print $2}')
##generation_date=$(
##    stat --format %W "$(readlink -f $NIX_SYSTEM)" | jq -r 'strflocaltime("%Y-%m-%d %H:%M:%S")'
##)
##generation_nixos_version=$(cat $NIX_SYSTEM/nixos-version)
#
##generation_prefix="Generation "
##commit_message=$(
##    jj show --summary | grep -e "^    " -e '^$' | tail -n +2 | head -n -1 | cut -c 5- |
##        grep -v "^$generation_prefix" | grep -v '^(no description set)$' || true
##)
##generation="$generation_number $generation_date $generation_nixos_version"
##echo -e "$commit_message\n\n$generation_prefix$generation" | jj describe --stdin &> /dev/null
#
#success "Successfully built NixOS configuration!"
##hint "($generation_prefix$generation)"
#popd &> /dev/null
