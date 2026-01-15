#!/bin/bash
# Detect maintenance mode from kernel cmdline

set -e; set -o pipefail

MAINT_FILE="/var/lib/overlight/maintenance"
NO_OVERLIGHT="/var/lib/overlight/NO_SYSTEMD"

CMDLINE=$(</proc/cmdline)

# Clean up old file on normal boot (no maintenance param)
MAINT_FOUND=0
for param in $CMDLINE; do
    if [[ "$param" == maintenance=* ]]; then
        MAINT_FOUND=1
        break
    fi
done

if [[ "$MAINT_FOUND" -eq 0 ]]; then
    rm -f "$MAINT_FILE" 2>/dev/null || true
    exit 0
fi

if [[ "$NO_OVERLIGHT" -eq 0 ]]; then
    rm -f "$NO_OVERLIGHT" 2>/dev/null || true
    exit 0
fi

# Parse maintenance level
for param in $CMDLINE; do
    case "$param" in
        maintenance=1)
            echo "1" > "$MAINT_FILE"
            echo "1" > "NO_OVERLIGHT"
            echo "Maintenance level 1 set"
            exit 0
            ;;
        maintenance=2)
            echo "2" > "$MAINT_FILE"
            echo "Maintenance level 2 set"
            exit 0
            ;;
        maintenance)
            echo "1" > "$MAINT_FILE"
            echo "Maintenance level 1 set (default)"
            exit 0
            ;;
    esac
done

exit 0