#!/bin/bash
# /usr/lib/overlight/bin/shutdown-clean.sh

NEWROOT="/newroot"
STAGE0_MOUNT="$NEWROOT/mnt/stage0"

# Clean work directories
rm -rf /home/user/work/* 2>/dev/null || true

# Unmount in reverse order
umount -f "$STAGE0_MOUNT" 2>/dev/null || true
umount -f "$NEWROOT" 2>/dev/null || true
umount -f /mnt 2>/dev/null || true

echo "OverLight shutdown complete"