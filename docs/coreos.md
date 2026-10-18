# CoreOS Setup Guide
Various setup tasks after installation is complete.

## Borg Backups
Assumes a Bazzite machine:
- is configured with the `bazzite` target of these dotfiles
- is available over mDNS (a `*.local` hostname)
- has the default Bazzite SSH server enabled
- has an existing backup drive mounted at `/var/mnt/backup`

```bash
~/.dotfiles/scripts/configure-coreos-backups.bash
```
