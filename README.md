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
- `scripts/generate-config.sh`：在 `olddefconfig` 之后做的针对性修改（Zen 4、NFSD/CIFS、BBR、AX200、USB4）。
