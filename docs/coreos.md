# CoreOS Setup Guide
Various setup tasks after installation is complete.

## LUKS Recovery Passphrase
Add a recovery passphrase in case the configured Tang server is unreachable.

```bash
# find root device
DEV=$(lsblk -pnro NAME,LABEL,FSTYPE | awk '$2 == "luks-root" && $3 == "crypto_LUKS" {print $1}')

# make sure device was found correctly
echo $DEV

# add recovery passphrase
sudo bash -c "
  cryptsetup luksAddKey --verify-passphrase --key-file <(clevis luks pass -d "$DEV" -s 1) "$DEV"
"

# check that passphrase was added
sudo cryptsetup luksDump "$DEV"

# verify passphrase
sudo cryptsetup open --test-passphrase "$DEV"
```

## Borg Backups
Assumes a Bazzite machine:
- is configured with the `bazzite` target of these dotfiles
- is available over mDNS (a `*.local` hostname)
- has the default Bazzite SSH server enabled
- has an existing backup drive mounted at `/var/mnt/backup`

```bash
~/.dotfiles/scripts/configure-coreos-backups.bash
```
