#!/bin/bash
# Runs wallust and adjusts waybar transparency based on wallpaper top strip brightness

if [ -z "$1" ]; then
    echo "Usage: wallust_run.sh <wallpaper_path>"
    exit 1
fi

# Run wallust to generate colors
wallust run "$1"

# Read the generated background color from style.css
BG=$(grep -oP 'alpha\(#\K[0-9A-Fa-f]{6}' ~/.config/waybar/style.css | head -1)

if [ -z "$BG" ]; then
    exit 0
fi

# Analyze the TOP STRIP of the wallpaper (top 5%) where waybar actually sits
# Crop top strip, scale to 1x1 pixel, get average brightness
TOP_BRIGHTNESS=$(magick "$1" -gravity North -crop 100%x5%+0+0 -resize 1x1! -format "%[fx:round((0.299*r + 0.587*g + 0.114*b) * 255)]" info:)

# Map brightness to alpha:
# Dark top area (0)    -> low alpha (0.2) = more transparent
# Light top area (255) -> high alpha (0.75) = more opaque, keep text readable
ALPHA=$(awk "BEGIN { printf \"%.2f\", 0.45 + ($TOP_BRIGHTNESS / 255.0) * 0.45 }")

# Replace the alpha value in style.css
sed -i "s/alpha(#${BG}, [0-9.]*)/alpha(#${BG}, ${ALPHA})/" ~/.config/waybar/style.css

# Restart waybar
killall waybar 2>/dev/null
waybar &disown

echo "Top strip brightness: ${TOP_BRIGHTNESS}/255 | Alpha: ${ALPHA}"
