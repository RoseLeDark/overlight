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
if mount "$STAGE0_ROOT" "$STAGE0_MOUNT" 2>/dev/null; then
    echo "Stage 0 mounted at $STAGE0_MOUNT"
    
    # Create access script in overlay
    cat > /newroot/usr/local/bin/stage0-access << 'EOF'
#!/bin/bash
echo "Stage 0 is mounted at /mnt/stage0"
echo ""
echo "Quick commands:"
echo "  stage0-shell    - Open Stage 0 bash"
echo "  ls /mnt/stage0  - Browse Stage 0"
echo ""
echo "To exit maintenance:"
echo "  rm /var/lib/overlight/maintenance.level"
echo "  reboot"
EOF
    chmod +x /newroot/usr/local/bin/stage0-access
fi