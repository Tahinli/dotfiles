#!/bin/bash
# Rofi wallpaper picker for niri — updates awww, wallust, and waybar.
#
# This is the niri twin of ~/.config/scripts/hyprland/wallpaper_picker.sh.
# Everything above the "Apply" section is identical; only the backend differs:
# hyprpaper talks over Hyprland's IPC socket (path built from
# $HYPRLAND_INSTANCE_SIGNATURE) and cannot run here, so awww replaces it.
#
# Unlike hyprpaper there is no config file to rewrite and no process to kill:
# awww-daemon stays up and `awww img` swaps the image at runtime.

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
THUMB_DIR="$HOME/.cache/wallpaper_thumbs"
STATE_FILE="$HOME/.cache/current_wallpaper"

# Generate thumbnail cache (only for new/changed images)
mkdir -p "$THUMB_DIR"

# Remove orphan thumbnails for deleted wallpapers
for thumb in "$THUMB_DIR"/*.png; do
    [ -f "$thumb" ] || continue
    name=$(basename "$thumb" .png)
    if ! find "$WALLPAPER_DIR" -maxdepth 1 -name "$name" -print -quit | grep -q .; then
        rm -f "$thumb"
    fi
done

# Generate thumbnails for new/changed wallpapers
find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | while read -r img; do
    name=$(basename "$img")
    thumb="$THUMB_DIR/$name.png"
    if [ ! -f "$thumb" ] || [ "$img" -nt "$thumb" ]; then
        magick "$img" -thumbnail 128x80 "$thumb" &
    fi
done
wait

# List image files with cached thumbnails in a grid rofi
SELECTED=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort | while read -r img; do
    name=$(basename "$img")
    echo -en "${name}\0icon\x1f${THUMB_DIR}/${name}.png\n"
done | rofi -dmenu -p "Wallpaper" -i -show-icons \
    -theme-str 'listview { columns: 4; lines: 3; flow: horizontal; }' \
    -theme-str 'element { orientation: vertical; }' \
    -theme-str 'element-icon { size: 100px; }' \
    -theme-str 'element-text { horizontal-align: 0.5; }')

if [ -z "$SELECTED" ]; then
    exit 0
fi

WALLPAPER="$WALLPAPER_DIR/$SELECTED"

if [ ! -f "$WALLPAPER" ]; then
    notify-send "Wallpaper Picker" "File not found: $WALLPAPER"
    exit 1
fi

# Apply: awww holds the wallpaper, wallust regenerates the palette.
# Start the daemon if it is not already up (also covers a crashed daemon).
if ! awww query >/dev/null 2>&1; then
    awww-daemon >/dev/null 2>&1 &
    disown
    for _ in $(seq 20); do
        awww query >/dev/null 2>&1 && break
        sleep 0.1
    done
fi

awww img --transition-type simple "$WALLPAPER" &
wallust run -qs "$WALLPAPER" &
wait

# Remember the choice so the daemon can be restored on the next login.
echo "$WALLPAPER" > "$STATE_FILE"

killall waybar 2>/dev/null
waybar &disown
notify-send "Wallpaper Picker" "Applied: $SELECTED"
