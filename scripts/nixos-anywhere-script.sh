#!/usr/bin/env bash

installhost=$1
targethost=$2
sshopts=$3

# Create a temporary directory
temp=$(mktemp -d)

# Function to cleanup temporary directory on exit
cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

# Create the directory where sshd expects to find the host keys
install -d -m755 "$temp/persist/system/sops-keys/sops/age"

# Decrypt your private key from the password store and copy it to the temporary directory
cat /sops-keys/sops/age/keys.txt > "$temp/persist/system/sops-keys/sops/age/keys.txt"

# Set the correct permissions so sshd will accept the key
chmod 600 "$temp/persist/system/sops-keys/sops/age/keys.txt"

# Install NixOS to the host system with our secrets
nixos-anywhere --extra-files "$temp" --flake .#$installhost --target-host $targethost $sshopts
