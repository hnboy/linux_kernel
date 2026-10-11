#!/bin/bash
# Install linux-custom packages, generate initramfs and a systemd-boot entry.
# The linux-lts kernel and its boot entry are left untouched and remain the fallback.
#
# Usage: sudo ./scripts/install.sh [directory-with-pkg-files]
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

PKG_DIR="${1:-.}"
shopt -s nullglob
PKGS=("$PKG_DIR"/linux-custom-*.pkg.tar.zst)
shopt -u nullglob
if [ "${#PKGS[@]}" -eq 0 ]; then
  echo "No linux-custom-*.pkg.tar.zst found in $PKG_DIR" >&2
  exit 1
fi

ENTRIES=/boot/loader/entries
LOADER_CONF=/boot/loader/loader.conf

echo "Running kernel : $(uname -r)"
echo "Packages       : ${PKGS[*]}"

# 1. Backup boot loader config so it can be restored by hand if needed
BACKUP="/boot/loader-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
cp -a /boot/loader/. "$BACKUP/"
echo "Boot loader backed up to $BACKUP"

# 2. Install packages
pacman -U --needed "${PKGS[@]}"

KVER=$(ls -1 /usr/lib/modules | grep -- '-custom$' | sort -V | tail -1)
echo "Installed module dir: $KVER"
depmod -a "$KVER"

# 3. Generate initramfs (default + fallback images)
mkinitcpio -p linux-custom

# 4. systemd-boot entry: clone the LTS entry and point it at the new kernel
LTS_ENTRY=$(grep -l 'vmlinuz-linux-lts' "$ENTRIES"/*.conf 2>/dev/null | head -1 || true)
if [ -n "$LTS_ENTRY" ]; then
  NEW_ENTRY="$(dirname "$LTS_ENTRY")/arch-custom.conf"
  sed -e 's/vmlinuz-linux-lts/vmlinuz-linux-custom/g' \
      -e 's/initramfs-linux-lts/initramfs-linux-custom/g' \
      -e "s/^title.*/title   Arch Linux (custom $KVER)/" \
      "$LTS_ENTRY" > "$NEW_ENTRY"
  echo "Created boot entry: $NEW_ENTRY"

  # Make the custom kernel the default; LTS stays in the menu as fallback
  if [ -f "$LOADER_CONF" ]; then
    sed -i '/^default /d' "$LOADER_CONF"
    echo "default arch-custom.conf" >> "$LOADER_CONF"
  fi
else
  echo "WARNING: no linux-lts boot entry found in $ENTRIES." >&2
  echo "Create a systemd-boot entry for /vmlinuz-linux-custom and /initramfs-linux-custom.img manually." >&2
fi

echo
echo "Done. Reboot to start $KVER."
echo "Fallback: at the systemd-boot menu choose the 'linux-lts' entry,"
echo "or run:  sudo bootctl set-default <lts-entry>.conf"
