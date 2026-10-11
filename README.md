# Custom Linux Kernel (Arch Linux)

GitHub Actions 在 `archlinux:base-devel` 容器中用 `makepkg` 编译最新 stable 内核，
产出 `linux-custom` 和 `linux-custom-headers` 两个 `.pkg.tar.zst` 包。

目标机器：AMD Ryzen 7 7840HS / Radeon 780M / RTL8125 2.5GbE / AX200 / USB4，作为远程开发 + NAS 使用。

## 构建

Actions 页面 → **Build Custom Kernel** → **Run workflow**，可填版本号（如 `7.2.9`），留空则取 kernel.org 最新 stable。
每周日 03:00 UTC 也会自动构建。产物在 Actions artifact 和 Release 中。

## 安装

```bash
mkdir -p ~/kernel-pkgs && cd ~/kernel-pkgs
# 下载 Release 中的两个 .pkg.tar.zst，然后：
sudo /path/to/kernel/scripts/install.sh ~/kernel-pkgs
sudo reboot
```

脚本会：备份 `/boot/loader`、`pacman -U` 安装、生成 initramfs、基于 linux-lts 的启动项创建 `arch-custom.conf` 并设为默认。

## 回退

- 开机时在 systemd-boot 菜单选择 `linux-lts` 启动项（原内核未被删除）。
- 永久回退：`sudo bootctl set-default <lts-entry>.conf`，或把 `/boot/loader/loader.conf` 恢复为备份。
- 卸载新内核：`sudo pacman -R linux-custom-headers linux-custom`。

## 配置

- `config/base.config`：当前机器的运行配置（6.18 LTS 导出）。
- `config/lsmod.txt`：目标机器 `lsmod` 输出。构建时通过 `make localmodconfig` 只保留这些模块（约 6000 个模块降到约 200 个），以缩短编译时间。
- `scripts/generate-config.sh`：在裁剪之后做的针对性修改（Zen 4、NFSD/CIFS、BBR、AX200、USB4、必需驱动，并关闭 DEBUG_INFO/BTF 和 Rust）。

构建顺序：`base.config` → `olddefconfig` → `localmodconfig`（读 `lsmod.txt`）→ `generate-config.sh` → `olddefconfig`。

### 更新 lsmod.txt

在目标机器上、所有日常使用的硬件和文件系统都已工作的状态下采集：

```bash
lsmod > config/lsmod.txt
```

### 裁剪后缺驱动怎么办

如果某个硬件或文件系统在新内核上不工作，原因通常是采集 `lsmod.txt` 时它没有加载。处理方式：

1. 在目标机器上插入/挂载该设备后，重新执行 `lsmod > config/lsmod.txt` 并提交；或
2. 在 `scripts/generate-config.sh` 中用 `$CFG --module <SYMBOL>` 强制启用该驱动。

### 已知限制

- 关闭了 DEBUG_INFO 和 BTF：`bpftrace`、CO-RE 的 eBPF 程序、`crash`、`perf` 的符号解析等工具将无法使用。
- Rust 支持已关闭，当前配置中没有 Rust 驱动。
