#!/bin/bash
set -e

KVER="${KVER:-$(make kernelversion 2>/dev/null || echo 'unknown')}"
OUTPUT_DIR="/output"
PKGVER="${KVER}-1"

echo "Building kernel ${KVER}..."

make -j$(nproc)

echo "Installing modules to temporary directory..."
TMP_MODULES=$(mktemp -d)
make modules_install INSTALL_MOD_PATH="$TMP_MODULES"

echo "Copying kernel image..."
mkdir -p "$TMP_MODULES/boot"
cp arch/x86/boot/bzImage "$TMP_MODULES/boot/vmlinuz-linux-custom"

echo "Creating kernel package..."
mkdir -p "$OUTPUT_DIR"

# Create a tarball with the package structure
PKG_TMP=$(mktemp -d)

mkdir -p "$PKG_TMP/usr/lib/modules/$KVER"
mkdir -p "$PKG_TMP/boot"
mkdir -p "$PKG_TMP/usr/share/doc/linux-custom"

cp arch/x86/boot/bzImage "$PKG_TMP/boot/vmlinuz-linux-custom"
cp -r "$TMP_MODULES/usr/lib/modules/$KVER/"* "$PKG_TMP/usr/lib/modules/$KVER/"
cp .config "$PKG_TMP/usr/share/doc/linux-custom/config"
cp vmlinux "$PKG_TMP/usr/lib/modules/$KVER/vmlinux" 2>/dev/null || true

# Create .PKGINFO
cat > "$PKG_TMP/.PKGINFO" << EOF
pkgname = linux-custom
pkgver = $PKGVER
pkgdesc = Custom Linux kernel for AMD Ryzen 7 7840HS with NAS and remote development optimizations
url = https://github.com/yourusername/kernel
builddate = $(date +%s)
packager = Custom Kernel Builder
size = $(du -sb "$PKG_TMP" | cut -f1)
arch = x86_64
license = GPL2
depend = coreutils
depend = kmod
depend = mkinitcpio
EOF

# Create .MTREE
cd "$PKG_TMP"
find . -type f -o -type l -o -type d | sort | \
  file-type | \
  sed 's/^\.\/\([^:]*\):\(.*\)$/\1 \2/' > "$PKG_TMP/.MTREE"
cd - > /dev/null

# Build the package
tar -czf "$OUTPUT_DIR/linux-custom-${PKGVER}-x86_64.tar.zst" \
  -C "$PKG_TMP" .

echo "Creating headers package..."
HEADERS_TMP=$(mktemp -d)
mkdir -p "$HEADERS_TMP/usr/lib/modules/$KVER/build"

make headers_install INSTALL_HDR_PATH="$HEADERS_TMP/usr/lib/modules/$KVER/build"
cp -r include "$HEADERS_TMP/usr/lib/modules/$KVER/build/"
cp -r arch/x86/include "$HEADERS_TMP/usr/lib/modules/$KVER/build/arch/x86/"
cp Makefile "$HEADERS_TMP/usr/lib/modules/$KVER/build/"
cp Kconfig "$HEADERS_TMP/usr/lib/modules/$KVER/build/" 2>/dev/null || true
cp .config "$HEADERS_TMP/usr/lib/modules/$KVER/build/"
cp Module.symvers "$HEADERS_TMP/usr/lib/modules/$KVER/build/" 2>/dev/null || true

mkdir -p "$HEADERS_TMP/usr/share/doc/linux-custom-headers"
cat > "$HEADERS_TMP/.PKGINFO" << EOF
pkgname = linux-custom-headers
pkgver = $PKGVER
pkgdesc = Headers for custom Linux kernel $KVER
url = https://github.com/yourusername/kernel
builddate = $(date +%s)
packager = Custom Kernel Builder
size = $(du -sb "$HEADERS_TMP" | cut -f1)
arch = x86_64
license = GPL2
EOF

cd "$HEADERS_TMP"
find . -type f -o -type l -o -type d | sort | \
  file-type | \
  sed 's/^\.\/\([^:]*\):\(.*\)$/\1 \2/' > "$HEADERS_TMP/.MTREE"
cd - > /dev/null

tar -czf "$OUTPUT_DIR/linux-custom-headers-${PKGVER}-x86_64.tar.zst" \
  -C "$HEADERS_TMP" .

echo "Cleaning up..."
rm -rf "$TMP_MODULES" "$PKG_TMP" "$HEADERS_TMP"

echo "Build complete!"
echo "Kernel package: $OUTPUT_DIR/linux-custom-${PKGVER}-x86_64.tar.zst"
echo "Headers package: $OUTPUT_DIR/linux-custom-headers-${PKGVER}-x86_64.tar.zst"
