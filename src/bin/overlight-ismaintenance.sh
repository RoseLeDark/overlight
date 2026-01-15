#!/bin/bash
# Detect maintenance mode from kernel cmdline

set -e

MAINT_FILE="/var/lib/overlight/maintenance"

# Clean up old file on normal boot (no maintenance param)
MAINT_FOUND=0
for param in $(cat /proc/cmdline); do
    if [[ "$param" == maintenance=* ]]; then
        MAINT_FOUND=1
        break
    fi
done

if [ "$MAINT_FOUND" -eq 0 ]; then
    # Normal boot - remove maintenance file if exists
    rm -f "$MAINT_FILE" 2>/dev/null || true
    exit 0
fi

# Parse maintenance level
for param in $(cat /proc/cmdline); do
    case "$param" in
        maintenance=1)
            echo "1" > "$MAINT_FILE"
            echo "Maintenance level 1 set"
            exit 0
            ;;
        maintenance=2)
            echo "2" > "$MAINT_FILE"
            echo "Maintenance level 2 set"
            exit 0
            ;;
        maintenance)
            # Default to level 1 if no number specified
            echo "1" > "$MAINT_FILE"
            echo "Maintenance level 1 set (default)"
            exit 0
            ;;
    esac
done

exit 0