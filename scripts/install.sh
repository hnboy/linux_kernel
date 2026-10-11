#!/bin/bash
set -e

KERNEL_PKG=""
HEADERS_PKG=""

for arg in "$@"; do
    case "$arg" in
        *.pkg.tar.zst|*.tar.zst)
            if [[ "$arg" == *"headers"* ]]; then
                HEADERS_PKG="$arg"
            else
                KERNEL_PKG="$arg"
            fi
            ;;
    esac
done

if [ -z "$KERNEL_PKG" ] && [ -z "$HEADERS_PKG" ]; then
    KERNEL_PKG=$(ls -t linux-custom-*-x86_64.tar.zst 2>/dev/null | grep -v headers | head -1)
    HEADERS_PKG=$(ls -t linux-custom-headers-*-x86_64.tar.zst 2>/dev/null | head -1)
fi

if [ -z "$KERNEL_PKG" ]; then
    echo "Error: No kernel package found."
    echo "Usage: $0 [kernel-package.tar.zst] [headers-package.tar.zst]"
    exit 1
fi

echo "=== Custom Kernel Installer ==="
echo "Kernel package: $KERNEL_PKG"
echo "Headers package: ${HEADERS_PKG:-not provided}"
echo ""

CURRENT_KERNEL=$(uname -r)
echo "Current kernel: $CURRENT_KERNEL"
echo ""

# Backup systemd-boot entries
echo "Backing up boot entries..."
if [ -d /boot/loader/entries ]; then
    sudo mkdir -p /boot/loader/entries/backup
    sudo cp /boot/loader/entries/*.conf /boot/loader/entries/backup/ 2>/dev/null || true
    echo "Boot entries backed up to /boot/loader/entries/backup/"
fi

# Install kernel
echo "Installing kernel package..."
sudo pacman -U --noconfirm "$KERNEL_PKG"

# Install headers if provided
if [ -n "$HEADERS_PKG" ]; then
    echo "Installing headers package..."
    sudo pacman -U --noconfirm "$HEADERS_PKG"
fi

# Generate initramfs
echo "Generating initramfs..."
if [ -f /etc/mkinitcpio.d/linux-custom.preset ]; then
    sudo mkinitcpio -p linux-custom
else
    echo "No preset found, creating default preset..."
    sudo mkinitcpio -p linux-custom 2>/dev/null || {
        echo "Creating manual initramfs..."
        sudo mkinitcpio -g /boot/initramfs-linux-custom.img
    }
fi

# Register with systemd-boot
echo "Registering with systemd-boot..."
sudo kernel-install add "$(make -s kernelversion 2>/dev/null || echo "$CURRENT_KERNEL")" /boot/vmlinuz-linux-custom 2>/dev/null || true

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Boot entries:"
ls /boot/loader/entries/*.conf 2>/dev/null | while read -r entry; do
    title=$(grep "^title" "$entry" | sed 's/title\s*//')
    echo "  - $title"
done

echo ""
echo "To reboot into the new kernel: sudo reboot"
echo ""
echo "Fallback: Select 'linux-lts' in the boot menu if issues occur."
echo "To remove: sudo kernel-install remove <version>"
