#!/bin/bash
# Apply hardware / use-case tweaks to the kernel .config.
# Run from the kernel source root after `make olddefconfig`.
# Only touches options that matter for this machine; everything else
# (KALLSYMS, KPROBES, FTRACE, PREEMPT, HZ, ...) keeps the base.config value.
set -euo pipefail

CFG=scripts/config

# Build identity -> modules dir becomes /usr/lib/modules/<ver>-custom
$CFG --set-str LOCALVERSION "-custom"
$CFG --disable LOCALVERSION_AUTO

# CPU: no Zen-specific option exists upstream (MZEN4/MNATIVE_AMD are not in
# mainline); the kernel keeps the default -march=x86-64 -mtune=generic.

# NAS: NFS server (v4) and SMB/CIFS client+server
$CFG --module NFSD
$CFG --enable NFSD_V4
$CFG --module CIFS
$CFG --enable CIFS_XATTR     # CIFS_POSIX depends on it; localmodconfig drops it
$CFG --enable CIFS_POSIX

# Network: BBR as default congestion control (built-in so it is the default)
$CFG --enable TCP_CONG_BBR
$CFG --set-str DEFAULT_TCP_CONG bbr

# Wi-Fi 6 AX200 (iwlwifi + mvm) and USB4 / Thunderbolt
$CFG --module IWLWIFI
$CFG --module IWLMVM
$CFG --module USB4          # includes Thunderbolt (no separate THUNDERBOLT symbol)
$CFG --module USB4_NET      # thunderbolt-net: Mac <-> Linux networking over TB4 cable

# Drivers/filesystems that must exist even if they were not loaded when
# config/lsmod.txt was captured (localmodconfig drops anything not in that list).
$CFG --module R8169          # RTL8125 2.5GbE
$CFG --module NVME_CORE      # external NVMe SSD enclosure
$CFG --module BLK_DEV_NVME
$CFG --module USB_STORAGE    # USB-bridged SSD enclosures
$CFG --module USB_UAS
$CFG --module USB_NET_DRIVERS   # parent menu; localmodconfig drops it, children need it
$CFG --module USB_USBNET     # USB network adapters
$CFG --module USB_RTL8152
$CFG --module USB_NET_CDC_NCM
$CFG --module EXT4_FS
$CFG --module BTRFS_FS
$CFG --module XFS_FS

# Build speed: no debug info / BTF, no Rust (no Rust drivers are enabled)
# DEBUG_INFO is derived from the "Debug information" choice: clear every
# DWARF member (base.config has DWARF5=y) and select NONE explicitly.
$CFG --disable DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
$CFG --disable DEBUG_INFO_DWARF4
$CFG --disable DEBUG_INFO_DWARF5
$CFG --disable DEBUG_INFO_REDUCED
$CFG --enable DEBUG_INFO_NONE
$CFG --disable DEBUG_INFO_BTF
$CFG --disable DEBUG_INFO_BTF_MODULES
$CFG --disable RUST

# Normalise dependent choices after the edits above
make olddefconfig
