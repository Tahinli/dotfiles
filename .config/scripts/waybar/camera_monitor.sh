#!/bin/bash

# Camera privacy monitor for waybar
# Detects camera device access and shows app info in tooltip

detect_camera() {
    if command -v lsof &> /dev/null; then
        if lsof /dev/video* 2>/dev/null | grep -qv "COMMAND"; then
            return 0
        fi
    fi
    return 1
}

get_camera_apps() {
    if command -v lsof &> /dev/null; then
        lsof /dev/video* 2>/dev/null | awk 'NR>1 {print $1}' | sort -u | paste -sd ', ' -
    fi
}

if detect_camera; then
    apps=$(get_camera_apps)
    if [ -n "$apps" ]; then
        # Output JSON with icon and tooltip containing app info
        tooltip_escaped=$(echo "$apps" | sed 's/"/\\"/g')
        echo "{\"text\": \"◉\", \"tooltip\": \"$tooltip_escaped\"}"
    else
        echo "{\"text\": \"◉\", \"tooltip\": \"Camera in use\"}"
    fi
fi
