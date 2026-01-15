# OverLight - Lightweight Overlay Boot System

## 🚀 What is OverLight?

**OverLight** is a minimalist, container-like boot system that allows you to run multiple Linux distributions from a single base system using **kernel-level OverlayFS**. Think of it as "Docker for your entire OS" but without the container overhead.

### Core Concept:
```
Stage 0 (Host) → OverlayFS → Stage 1 (Guest OS)
    ↓                    ↓
Arch Linux      +   SquashFS Image   =   Ubuntu/Debian/Fedora/etc.
```

## ✨ Key Features

- **Zero Container Overhead**: Uses native Linux OverlayFS, no Docker/Podman runtime
- **Instant OS Switching**: Boot into different Linux distributions in seconds
- **Maintenance Modes**: Built-in recovery system with different access levels
- **Storage Efficient**: Read-only SquashFS + writeable overlay layers
- **KISS Design**: Simple shell scripts, no complex orchestration
- **Stage 0 Isolation**: Host system remains clean and untouched

## Recommended Disk Layout

For optimal performance and organization, I recommend this partition scheme:

### Standard Partition Layout:

```text
/dev/sdX1:  Arch Linux Stage 0          [20-30GB]    ext4
/dev/sdX2:  Overlay OS Home             [Rest]       ext4/btrfs
/dev/sda3: OverLight Work/Upper         [20GB]       ext4  → /mnt/overlight in Stage 0 [optional]
```

#### FStab 

```
/etc/fstab in Stage 0
# ... your FSTAB
# add this:
/dev/sda3   /mnt/overlight     ext4        defaults
```


## Architecture

### Directory Structure:
```
/overlay/                  # Guest OS directory (configurable)
├── autoload               # Single line: default OS name
├── archlinux/
│   ├── rootfs.squashfs    # OS root filesystem
│   └── config.cfg         # Per-OS configuration
├── debian/
│   ├── rootfs.squashfs
│   └── config.cfg
└── ubuntu/
    ├── rootfs.squashfs
    └── config.cfg
```

### Boot Flow:
1. **Stage 0**: Minimal Arch Linux boots
2. **Cmdline Check**: Parse `maintenance=` parameters
3. **OS Selection**: Read `/overlay/autoload`
4. **OverlayFS Mount**: SquashFS (lower) + write layer (upper)
5. **Root Switch**: `switch_root` to guest OS
6. **Guest OS**: Your chosen distribution runs natively

## 🔧 Installation

### Quick Start:
```bash
git clone https://github.com/RoseLeDark/overlight.git
cd overlight
./configure --prefix=/usr --guest=/overlay
cd build
sudo make install
```

### Configuration Options:
```bash
# System-wide installation (recommended)
./configure --prefix=/usr --guest=/overlay

# Local testing
./configure --prefix=$HOME/.local --guest=$HOME/overlay-test

# Custom location
./configure --prefix=/opt/overlight --guest=/mnt/overlay-os
```

## ⚙️ Configuration

### 1. GRUB Setup (`/etc/grub.d/40_custom`):
```grub
menuentry "OverLight - Normal Boot" {
    linux /vmlinuz-linux root=/dev/sda2 rw quiet
    initrd /initramfs-linux.img
}

menuentry "OverLight - Maintenance 1 (Stage 0 Shell)" {
    linux /vmlinuz-linux root=/dev/sda2 rw maintenance=1
    initrd /initramfs-linux.img
}

menuentry "OverLight - Maintenance 2 (With Stage 0 Access)" {
    linux /vmlinuz-linux root=/dev/sda2 rw maintenance=2
    initrd /initramfs-linux.img
}
```
Then run: `sudo grub-mkconfig -o /boot/grub/grub.cfg`

### 2. Create OS Image:
```bash
# Example: Create Arch Linux image
mkdir /tmp/arch-root
sudo pacstrap -c /tmp/arch-root base base-devel 
# See wiki for configuration without bootloader
# Yout last step:
sudo mksquashfs /tmp/arch-root /overlay/archlinux/rootfs.squashfs -comp xz

# Edit autoload
echo "archlinux" > /overlay/autoload


# Create SHA256 Sum from /overlay/archlinux/rootfs.squashfs
sha256sum "/overlay/archlinux/rootfs.squashfs" 

# Copy Sum from the terminal 
```

### 3. Configuration File (`/overlay/archlinux/config.cfg`):
```ini
ROOTFS=rootfs.squashfs
ROOTFS_SUM="YOUR-SHA256-SUM"  # Replace YOUR-SHA256-SUM with the created sha256sum from rootfs.squashfs
OVERL_CMDLINE=/sbin/Init
```

## 🛠️ Usage

### Command Line Interface:
```bash
# Show system status
sudo overlightcfg.sh status

# List available OS images
sudo overlightcfg.sh list-os

# Switch to different OS
sudo overlightcfg.sh switch-os debian

# Boot into overlay (usually automatic)
sudo overlightcfg.sh boot

# Clean shutdown
sudo overlightcfg.sh shutdown

# verifine all guest OS's
sudo overlightcfg.sh verify --all

# verify a given guest OS
sudo overlightcfg.sh verify archlinux # orother name
```

### Boot Modes:
| Mode | Kernel Parameter | Behavior |
|------|-----------------|----------|
| Normal | (none) | Boot into selected overlay OS |
| Maintenance 1 | `maintenance=1` | Stop at Stage 0 shell |
| Maintenance 2 | `maintenance=2` | Boot overlay OS with Stage 0 at `/mnt/stage0` |

## 🔍 Maintenance & Recovery

### Accessing Stage 0:
```bash
# From GRUB: Select "Maintenance 1"
# You'll land in Stage 0 bash where you can:
ls /overlay/                      # Check OS images
cp new-image.squashfs /overlay/ubuntu/  # Install new OS
rm /var/lib/overlight/maintenance # Exit maintenance mode
reboot
```

### Emergency Shell (Maintenance 1):
- Full access to Stage 0 filesystem
- Can repair/install new OS images
- Network access available
- Run any Stage 0 tools

### Stage 0 Access from Guest (Maintenance 2):
- Overlay OS runs normally
- Stage 0 mounted at `/mnt/stage0`
- Access Stage 0 files while in guest OS
- Perfect for debugging and file recovery

## 🐛 Troubleshooting

### Common Issues:

1. **OverLight service won't start**
   ```bash
   journalctl -u overlight.service
   systemctl status overlight-early.service
   ```

2. **Cannot mount squashfs**
   ```bash
   # Check if file exists and is valid
   unsquashfs -s /overlay/archlinux/rootfs.squashfs
   ```

3. **Maintenance mode not working**
   ```bash
   # Check if maintenance file was created
   ls -la /var/lib/overlight/
   cat /proc/cmdline
   ```

4. **Home partition not mounting**
   ```bash
   # Check config.cfg and partition
   blkid
   lsblk
   ```

## 🏗️ Building OS Images

### From Existing Installation:
```bash
# 1. Boot into the OS you want to image
# 2. Create squashfs from running system
sudo mksquashfs / /tmp/rootfs.squashfs -comp xz -e /proc /sys /dev /run /tmp

# 3. Copy to overlay directory
sudo cp /tmp/rootfs.squashfs /overlay/newos/

# 4. Create SSHA 256 Sum
ROOTFS=/overlay/newos/rootfs.squashfs
ROOTFS_SUM=$(sha256sum "$ROOTFS" | awk '{print $1}')

# 5. Create config
echo "ROOTFS=$ROOTFS" > /overlay/newos/config.cfg
echo "ROOTFS_SUM=\"$ROOTFS_SUM\"" >> /overlay/newos/config.cfg
echo 'OVERL_CMDLINE=/sbin/Init' >> /overlay/newos/config.cfg
```

### Using debootstrap (Debian/Ubuntu):
```bash
sudo debootstrap stable /tmp/debian-root http://deb.debian.org/debian
sudo mksquashfs /tmp/debian-root /overlay/debian/rootfs.squashfs

ROOTFS=/overlay/debian/rootfs.squashfs
ROOTFS_SUM=$(sha256sum "$ROOTFS" | awk '{print $1}')

echo "ROOTFS=$ROOTFS" > /overlay/debian/config.cfg
echo "ROOTFS_SUM=\"$ROOTFS_SUM\"" >> /overlay/debian/config.cfg
echo 'OVERL_CMDLINE=/sbin/Init' >> /overlay/debian/config.cfg
```

## 📁 Project Structure

```
overlight/
├── configure                   # Configuration script
├── Makefile.in                 # Build template
├── install.sh                  # Auto build tool
├── src/                        # Source
│   ├── bin/                    # Core binaries
│   ├── etc/                    # Configuration templates
│   ├── examples/               # Example configs
│   ├── systemd/                # Service files
│   ├── overlight-install.sh.in # The Install Script (automatic call)
|   └── overlightcfg.sh.in      # Main control script
├── LICENSE              # GPLv3
└── README.md           # This file
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Development Setup:
```bash
# Clone and setup dev environment
git clone https://github.com/RoseLeDark/overlight.git
cd overlight
./configure --prefix=$HOME/.local --guest=/tmp/overlay-test
cd build
make
```

## 📄 License

OverLight is licensed under the **GNU General Public License v3.0**.

**Why GPLv3?**
- Ensures modifications remain open source
- Protects user freedoms
- Prevents commercialization without sharing improvements
- Compatible with most Linux distributions

## 🎯 Use Cases

### Ideal For:
- **Testing/Development**: Quick OS switching without VMs
- **Education**: Safe Linux learning environment
- **Kiosk/Public Systems**: Easy reset to clean state
- **Embedded Devices**: Multiple OS profiles on limited storage
- **Recovery Systems**: Built-in maintenance modes

### Not For:
- High-security isolation (use proper containers)
- Cloud deployments (use orchestration tools)
- Windows/macOS hosts (Linux kernel required)

## 🔗 Related Projects

- **SteamOS**: Similar A/B update concept
- **systemd-nspawn**: Lightweight container system
- **bootc**: Container-native booting
- **KIWI (openSUSE)**: Image builder with overlay support

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/RoseLeDark/overlight/issues)
- **Wiki**: Detailed documentation and examples
- **Discussions**: Community Q&A on GitHub

## 🚀 Getting Help

```bash
# Quick help
overlightcfg.sh --help

# Check system status
overlightcfg.sh status

# View logs
journalctl -u overlight.service -f
```


**OverLight**: When you need containers without the container complexity.

*"Boot anything, anywhere, with almost nothing."*