# Bazzite Setup Guide
Various setup tasks after installation is complete.

## Additional Drives (Internal and External)
Assumes a drive is already formatted as LUKSv2-encrypted Btrfs partition.

https://wiki.archlinux.org/title/Systemd-cryptenroll#Trusted_Platform_Module
```sh
# Ensure TPM device is usable
systemd-cryptenroll --tpm2-device=list

# Link TPM to LUKS container
sudo systemd-cryptenroll --tpm2-device=auto /dev/sdb1 # or /dev/nvme1n1p1

# Ensure TPM keyslot was added
sudo cryptsetup luksDump /dev/sdb1 # or /dev/nvme1n1p1
```

https://wiki.archlinux.org/title/Dm-crypt/System_configuration#Unlocking_in_late_userspace
```sh
# Look for LUKS container UUID
sudo blkid /dev/sdb1 # or /dev/nvme1n1p1

# Add line for backup drive (replace <uuid> with actual UUID):
# luks-<uuid> UUID=<uuid> none nofail         # for HDD
# luks-<uuid> UUID=<uuid> none nofail,discard # for SSD
sudo vim /etc/crypttab

# Add line for backup drive (replace <uuid> with actual UUID):
# /dev/mapper/luks-<uuid> /mnt/<mount-name> btrfs nosuid,nodev,nofail,noatime,x-gvfs-show,compress=zstd 0 0
sudo vim /etc/fstab
```

## Vorta
Import settings from `~/.dotfiles/configs/vorta/vorta.json`.

## Configure NextDNS
https://my.nextdns.io

```bash
# Update according to NextDNS dashboard instructions
sudo vim /etc/systemd/resolved.conf
```

## Configure Steam Game Recordings
https://store.steampowered.com/gamerecording#:~:text=Where%20are%20my%20recordings

> Game recordings (and their timeline) are shown in the in-game Overlay and in your Recordings & Screenshots viewer.
> From the Steam Desktop Client select View > Recordings & Screenshots. From your Steam Deck, select the Media tab from
> the main menu. You'll find the same content and capabilities in both places.
>
> You can choose where your recordings are stored on your hard drive from Steam > Settings > Game Recording. Steam is
> capturing both the video and the timeline in a raw format, if you'd like a video format (mp4) of your gameplay then
> you'll need to create a clip and export it.

## Select Performance Profile
https://docs.kde.org/trunk_kf6/en/powerdevil/kcontrol/powerdevil/index.html#:~:text=Switch%20to%20power%20profile

> Power profiles can also be changed on the fly through the Power &amp; Battery applet, as well as with keyboard
> shortcuts. Changing power profiles on the fly will not affect the settings in this module. If no brightness level is
> set in this settings module, the brightness will remain the same when switching between power states.
