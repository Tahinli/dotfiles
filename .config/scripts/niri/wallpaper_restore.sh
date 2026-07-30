#!/bin/bash

STATE_FILE="$HOME/.cache/current_wallpaper"
FALLBACK_DIR="$HOME/Pictures/Wallpapers"

if ! awww query >/dev/null 2>&1; then
    awww-daemon >/dev/null 2>&1 &
    disown
    for _ in $(seq 50); do
        awww query >/dev/null 2>&1 && break
        sleep 0.1
    done
fi

WALLPAPER=""

if [ -s "$STATE_FILE" ]; then
    WALLPAPER=$(cat "$STATE_FILE")
fi

if [ ! -f "$WALLPAPER" ]; then
    WALLPAPER=$(grep -oP '^\s*path\s*=\s*\K.*' "$HOME/.config/hypr/hyprpaper.conf" 2>/dev/null | head -1)
fi

if [ ! -f "$WALLPAPER" ]; then
    WALLPAPER=$(find "$FALLBACK_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort | head -1)
fi

if [ -f "$WALLPAPER" ]; then
    awww img --transition-type none "$WALLPAPER"
    echo "$WALLPAPER" > "$STATE_FILE"
fi
