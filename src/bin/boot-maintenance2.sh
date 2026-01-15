#!/bin/bash
# /usr/lib/overlight/bin/boot-maintenance2.sh

set -e

. /etc/overlight.cfg

# First, do normal boot
/usr/lib/overlight/bin/boot-normal.sh

# Then mount Stage 0
STAGE0_MOUNT="/newroot/mnt/stage0"
mkdir -p "$STAGE0_MOUNT"

# Try to mount Stage 0 root
if mount / "$STAGE0_MOUNT" 2>/dev/null; then
    echo "Stage 0 mounted at $STAGE0_MOUNT"
fi
