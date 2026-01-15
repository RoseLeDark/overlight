#!/bin/bash
# /usr/lib/overlight/bin/boot-normal.sh

set -e; set -o pipefail

. /etc/overlight.cfg

# Read selected OS
OS_NAME=$(cat "$OVERLAY_ROOT/autoload")
OS_DIR="$OVERLAY_ROOT/$OS_NAME"

# Load OS config
[ -f "$OS_DIR/config.cfg" ] && . "$OS_DIR/config.cfg"

# Defaults
ROOTFS="${ROOTFS:-rootfs.squashfs}"
SHARED_PATH="${SHARED_PATH:-/var/lib/overlight}"
NEWROOT="${NEWROOT:-/newroot}"
OVERL_CMDLINE="${OVERL_CMDLINE:-/sbin/init}"
SQUADFSLOOP="${SQUADFSLOOP:-/mnt/loop}"

UPPER_DIR="$SHARED_PATH/$OS_NAME/upper"
WORK_DIR="$SHARED_PATH/$OS_NAME/work"

# Validate
ROOTFS_PATH="$OS_DIR/$ROOTFS"
[ ! -f "$ROOTFS_PATH" ] && { echo "Rootfs not found: $ROOTFS_PATH"; exit 1; }

# SHA256 verification (optional)
if [ -n "$ROOTFS_SUM" ]; then
    echo "Verifying SHA256 checksum..."
    CALCULATED_SUM=$(sha256sum "$ROOTFS_PATH" | cut -d' ' -f1)
    
    if [ "$CALCULATED_SUM" != "$ROOTFS_SUM" ]; then
        echo "ERROR: SHA256 verification failed!"
        echo "Expected: $ROOTFS_SUM"
        echo "Got:      $CALCULATED_SUM"
        exit 1
    fi
    echo "$ROOTFS_PATH checksum verified"
fi


# Prepare
mkdir -p "$NEWROOT" "$UPPER_DIR" "$WORK_DIR" "$SQUADFSLOOP"

# Mount squashfs
mount -t squashfs -o loop,ro "$OS_DIR/$ROOTFS" "$SQUADFSLOOP" || {
    echo "Failed to mount squashfs"; exit 1
}

# Overlay mount mit Stage 0 upper/work
mount -t overlay overlay \
    -o "lowerdir=$SQUADFSLOOP,upperdir=$UPPER_DIR,workdir=$WORK_DIR" \
    "$NEWROOT" || {
    echo "Failed to mount overlay"; exit 1
}

# Mount home if specified
if [ -n "$HOME_PARTITION" ] && [ -b "$HOME_PARTITION" ]; then
    mkdir -p "$NEWROOT/home/"
    mount "$HOME_PARTITION" "$NEWROOT/home/" || echo "Warning: Failed to mount home"
fi

# Switch root
mount --move /proc "$NEWROOT/proc"
mount --move /sys "$NEWROOT/sys"
mount --move /dev "$NEWROOT/dev"
mount --move /run "$NEWROOT/run"

# Switch to new root
exec switch_root "$NEWROOT" "$OVERL_CMDLINE"
