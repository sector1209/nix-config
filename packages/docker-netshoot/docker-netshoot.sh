# Variables
help_base="\
Usage: $(basename "${BASH_SOURCE[0]}") [target container]
"

# Output text colour functions
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

# Application logic
TARGET="${1:-}"

# Fail if no target container is given
if [[ -z $TARGET ]]; then
  echo "$help_base" >&2
  exit 1
fi

# Fail if target container doesn't exist
if ! docker inspect "$TARGET" &> /dev/null; then
  error "Error: container '$TARGET' not found or Docker is not running." >&2
  exit 1
fi

# Run docker command
exec docker run -it --rm --network "container:${TARGET}" nicolaka/netshoot
