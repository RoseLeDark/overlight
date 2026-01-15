#!/bin/bash
# /usr/lib/overlight/bin/shutdown-clean.sh
set -e; set -o pipefail

. /etc/overlight.cfg

NEWROOT="${NEWROOT:-/newroot}"

# Unmount in reverse order
umount -R "$NEWROOT" 2>/dev/null || true

echo "OverLight shutdown complete"