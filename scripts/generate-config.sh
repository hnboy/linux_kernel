#!/bin/bash
# Apply hardware / use-case tweaks to the kernel .config.
# Run from the kernel source root after `make olddefconfig`.
# Only touches options that matter for this machine; everything else
# (KALLSYMS, BTF, KPROBES, FTRACE, PREEMPT, HZ, ...) keeps the base.config value.
set -euo pipefail

CFG=scripts/config

# Build identity -> modules dir becomes /usr/lib/modules/<ver>-custom
$CFG --set-str LOCALVERSION "-custom"
$CFG --disable LOCALVERSION_AUTO

# CPU: AMD Zen 4 (Ryzen 7 7840HS)
$CFG --disable GENERIC_CPU
$CFG --enable MNATIVE_AMD

# NAS: NFS server (v4) and SMB/CIFS client+server
$CFG --module NFSD
$CFG --enable NFSD_V4
$CFG --module CIFS
$CFG --enable CIFS_POSIX

# Network: BBR as default congestion control (built-in so it is the default)
$CFG --enable TCP_CONG_BBR
$CFG --set-str DEFAULT_TCP_CONG bbr

# Wi-Fi 6 AX200 (iwlwifi + mvm) and USB4 / Thunderbolt
$CFG --module IWLWIFI
$CFG --module IWLMVM
$CFG --module USB4
$CFG --module THUNDERBOLT

# Normalise dependent choices after the edits above
make olddefconfig
