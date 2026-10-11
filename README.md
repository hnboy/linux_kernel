# Custom Linux Kernel Builder

为 AMD Ryzen 7 7840HS + NAS + 远程开发场景定制的 Linux 内核，通过 GitHub Actions 自动编译。

## 硬件配置

| 组件 | 型号 |
|------|------|
| CPU | AMD Ryzen 7 7840HS (Zen 4, 8C/16T) |
| GPU | AMD Radeon 780M |
| 内存 | 28GB DDR5 |
| 存储 | Micron 2550 1TB + ZHITAI Ti600 4TB (NVMe) |
| 网卡 | Realtek RTL8125 2.5GbE |
| Wi-Fi | Intel AX200 (Wi-Fi 6) |
| 其他 | USB4/Thunderbolt |

## 内核优化

- **CPU**: `CONFIG_MNATIVE_AMD` — Zen 4 原生调度优化
- **GPU**: `CONFIG_DRM_AMDGPU=y` — Radeon 780M 集成
- **存储**: NVMe 优化，ext4/XFS，NFS 服务器
- **网络**: 2.5GbE (RTL8125)，BBR 拥塞控制，Tailscale VPN
- **容器**: Docker 完整支持 (cgroup v2, overlayfs, bridge)
- **文件系统**: ext4, Btrfs, NFS, CIFS, XFS

## 使用方式

### 1. 构建

#### 手动触发
1. 进入 GitHub 仓库 Actions 页面
2. 选择 "Build Custom Kernel"
3. 点击 "Run workflow"
4. 可选输入特定版本号（如 `7.2.9`），留空则使用最新 stable

#### 自动构建
每周日凌晨 3:00 自动检查并构建最新 stable 版本

### 2. 安装

从 Release 下载两个包：
```bash
wget https://github.com/yourusername/kernel/releases/download/v7.2.9/linux-custom-7.2.9-1-x86_64.tar.zst
wget https://github.com/yourusername/kernel/releases/download/v7.2.9/linux-custom-headers-7.2.9-1-x86_64.tar.zst
```

运行安装脚本：
```bash
chmod +x scripts/install.sh
sudo ./scripts/install.sh linux-custom-7.2.9-1-x86_64.tar.zst linux-custom-headers-7.2.9-1-x86_64.tar.zst
```

或手动安装：
```bash
sudo pacman -U linux-custom-7.2.9-1-x86_64.tar.zst
sudo pacman -U linux-custom-headers-7.2.9-1-x86_64.tar.zst
sudo mkinitcpio -p linux-custom
sudo reboot
```

### 3. Fallback

如果新内核有问题：

1. **启动菜单选择**: 开机时在 systemd-boot 菜单选择 `linux-lts` 条目
2. **命令行回退**:
   ```bash
   sudo kernel-install remove 7.2.9-1-custom
   sudo mkinitcpio -p linux-lts
   sudo reboot
   ```

## 仓库结构

```
kernel/
├── .github/workflows/kernel-build.yml   # GitHub Actions 工作流
├── scripts/
│   ├── generate-config.sh               # 配置生成
│   ├── build-kernel.sh                  # 编译打包
│   └── install.sh                       # 本地安装脚本
├── config/
│   └── base.config                      # 从 /proc/config.gz 提取的基础配置
├── PKGBUILD.kernel                      # 内核包 PKGBUILD
├── PKGBUILD.headers                     # 头文件包 PKGBUILD
├── README.md
└── .gitignore
```

## License

GPL-2.0 (same as Linux kernel)
