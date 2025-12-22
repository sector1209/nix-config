### To install NixOS on a new host

1. Install the nixos-deploy-key.pub in /root/.ssh/authorized_keys on the target host

2.Run the following command:

```bash
./scripts/nixos-anywhere.sh <FLAKE HOST> <SSH TARGET> [EXTRA SSH OPTIONS]
```
