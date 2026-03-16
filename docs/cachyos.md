# CachyOS Setup Guide
Various setup tasks after installation is complete.

## Update Packages
```sh
sudo pacman -Syu
```

## Set up Wireless Regulatory Domain
https://wiki.cachyos.org/configuration/post_install_setup/#configure-wi-fi-regulatory-domain

```sh
# Uncomment `WIRELESS_REGDOM="US"` line
sudo vim /etc/conf.d/wireless-regdom
```

## Set up Secure Boot
https://wiki.cachyos.org/configuration/secure_boot_setup/

```sh
# Ensure Secure Boot is in setup mode
sudo sbctl status

# If not, reboot to BIOS settings
systemctl reboot --firmware-setup
```

```sh
# Ensure Secure Boot is in setup mode
sudo sbctl status

# Configure Secure Boot
sudo sbctl create-keys
sudo sbctl enroll-keys --microsoft

# Update Limine to support Secure Boot
sudo limine-enroll-config
sudo limine-update
```

```sh
# Ensure Secure Boot is enabled and out of setup mode
sudo sbctl status

# If not, reboot to BIOS settings
systemctl reboot --firmware-setup
```

```sh
# Ensure Secure Boot is enabled and out of setup mode
sudo sbctl status
```

## Link TPM to root drive LUKS encryption
https://wiki.archlinux.org/title/Systemd-cryptenroll#Trusted_Platform_Module

```sh
# Ensure TPM device is usable
systemd-cryptenroll --tpm2-device=list

# Link TPM to LUKS container
sudo systemd-cryptenroll --tpm2-device=auto /dev/nvme0n1p2

# Ensure TPM keyslot was added
sudo cryptsetup luksDump /dev/nvme0n1p2
```

## Configure Encrypted Backup Drive
Assumes drive is already formatted as LUKSv2-encrypted Btrfs drive.

https://wiki.archlinux.org/title/Systemd-cryptenroll#Trusted_Platform_Module

```sh
# Ensure TPM device is usable
systemd-cryptenroll --tpm2-device=list

# Link TPM to LUKS container
sudo systemd-cryptenroll --tpm2-device=auto /dev/sda1

# Ensure TPM keyslot was added
sudo cryptsetup luksDump /dev/sda1
```

https://wiki.archlinux.org/title/Dm-crypt/System_configuration#Unlocking_in_late_userspace

```sh
# Look for LUKS container UUID
sudo blkid /dev/sda1

# Add line for backup drive (replace <uuid> with actual UUID):
# luks-<uuid> UUID=<uuid> none
sudo vim /etc/crypttab

# Add line for backup drive (replace <uuid> with actual UUID):
# /dev/mapper/luks-<uuid> /media/backup  btrfs   defaults,noatime,compress=zstd:1,nofail,x-systemd.automount 0 0
sudo vim /etc/fstab
```

## Gaming / Steam
https://wiki.cachyos.org/configuration/gaming/

```bash
mkdir -p ~/.config/environment.d
echo << EOF > ~/.config/environment.d/gaming.conf
# Increase Nvidia's shader cache size to 12GB
__GL_SHADER_DISK_CACHE_SIZE=12000000000
EOF
```

## Remove Stale Windows Bootloader Entry
```sh
sudo limine-entry-tool --remove-os "Other systems and bootloaders"
```

## Allow KDE Connect through Firewall
```sh
sudo ufw allow 1714:1764/udp
sudo ufw allow 1714:1764/tcp
```
