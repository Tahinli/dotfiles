#!/bin/bash

# DateTime Info - Shows system uptime with seconds

# Get system uptime in seconds
uptime_seconds=$(cat /proc/uptime | awk '{print int($1)}')

# Convert to readable format with seconds
days=$((uptime_seconds / 86400))
hours=$(((uptime_seconds % 86400) / 3600))
minutes=$(((uptime_seconds % 3600) / 60))
seconds=$((uptime_seconds % 60))

# Build uptime string
uptime_str=""
if [ $days -gt 0 ]; then
    uptime_str="${days} day$([ $days -gt 1 ] && echo 's' || true)"
    [ $hours -gt 0 ] && uptime_str="$uptime_str, ${hours} hour$([ $hours -gt 1 ] && echo 's' || true)"
    [ $minutes -gt 0 ] && uptime_str="$uptime_str, ${minutes} minute$([ $minutes -gt 1 ] && echo 's' || true)"
    [ $seconds -gt 0 ] && uptime_str="$uptime_str, ${seconds} second$([ $seconds -gt 1 ] && echo 's' || true)"
elif [ $hours -gt 0 ]; then
    uptime_str="${hours} hour$([ $hours -gt 1 ] && echo 's' || true)"
    [ $minutes -gt 0 ] && uptime_str="$uptime_str, ${minutes} minute$([ $minutes -gt 1 ] && echo 's' || true)"
    [ $seconds -gt 0 ] && uptime_str="$uptime_str, ${seconds} second$([ $seconds -gt 1 ] && echo 's' || true)"
else
    uptime_str="${minutes} minute$([ $minutes -gt 1 ] && echo 's' || true), ${seconds} second$([ $seconds -gt 1 ] && echo 's' || true)"
fi

# Display with proper alignment
echo "Uptime"
echo "======"
echo ""
echo "  $uptime_str"
