# Maintainer: hnboy
# Builds two packages from one kernel source tree:
#   linux-custom          - kernel image + modules + mkinitcpio preset
#   linux-custom-headers  - build tree for external module builds (DKMS etc.)
# pkgver is overwritten by the CI workflow from kernel.org releases.json.

pkgbase=linux-custom
pkgname=('linux-custom' 'linux-custom-headers')
pkgver=7.2.9
pkgrel=1
pkgdesc='Custom Linux kernel tuned for Ryzen 7840HS, NAS and remote development'
url='https://www.kernel.org/'
arch=('x86_64')
license=('GPL-2.0-only')
makedepends=('bc' 'bison' 'cpio' 'flex' 'kmod' 'libelf' 'ncurses' 'openssl'
             'pahole' 'perl' 'python' 'rsync' 'tar' 'xz' 'zstd')
options=('!debug' '!strip')
source=("https://cdn.kernel.org/pub/linux/kernel/v${pkgver%%.*}.x/linux-${pkgver}.tar.xz")
sha256sums=('SKIP')

build() {
  cd "linux-${pkgver}"

  # Start from the target machine's running config (6.18 LTS), upgrade to this version
  cp "${startdir}/config/base.config" .config
  make olddefconfig

  # Hardware / use-case tweaks
  bash "${startdir}/scripts/generate-config.sh"

  make bzImage modules
}

package_linux-custom() {
  pkgdesc='Custom Linux kernel tuned for Ryzen 7840HS, NAS and remote development'
  depends=('coreutils' 'kmod' 'mkinitcpio')
  optdepends=('linux-firmware: hardware firmware')
  backup=('etc/mkinitcpio.d/linux-custom.preset')

  cd "linux-${pkgver}"
  local kver
  kver="$(make -s kernelrelease)"

  install -Dm644 "$(make -s image_name)" "${pkgdir}/boot/vmlinuz-linux-custom"

  make INSTALL_MOD_PATH="${pkgdir}/usr" modules_install
  rm -f "${pkgdir}/usr/lib/modules/${kver}/build" "${pkgdir}/usr/lib/modules/${kver}/source"

  install -d "${pkgdir}/etc/mkinitcpio.d"
  cat > "${pkgdir}/etc/mkinitcpio.d/linux-custom.preset" <<'EOF'
# mkinitcpio preset for linux-custom
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux-custom"
PRESETS=('default' 'fallback')
default_image="/boot/initramfs-linux-custom.img"
fallback_image="/boot/initramfs-linux-custom-fallback.img"
fallback_options="-S autodetect"
EOF
}

package_linux-custom-headers() {
  pkgdesc='Headers and build tree for the linux-custom kernel'
  depends=('linux-custom' 'gcc' 'make')

  cd "linux-${pkgver}"
  local kver dir
  kver="$(make -s kernelrelease)"
  dir="${pkgdir}/usr/lib/modules/${kver}/build"

  install -Dm644 .config "${dir}/.config"
  install -Dm644 Makefile "${dir}/Makefile"
  install -Dm644 Module.symvers "${dir}/Module.symvers"
  install -Dm644 Kconfig "${dir}/Kconfig"
  cp -a -t "${dir}" include scripts
  install -d "${dir}/arch/x86"
  cp -a -t "${dir}/arch/x86" arch/x86/include
  cp -a arch/x86/Makefile* "${dir}/arch/x86/"
}
