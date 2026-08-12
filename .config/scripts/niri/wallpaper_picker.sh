#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
THUMB_DIR="$HOME/.cache/wallpaper_thumbs"
STATE_FILE="$HOME/.cache/current_wallpaper"

mkdir -p "$THUMB_DIR"

for thumb in "$THUMB_DIR"/*.png; do
    [ -f "$thumb" ] || continue
    name=$(basename "$thumb" .png)
    if ! find "$WALLPAPER_DIR" -maxdepth 1 -name "$name" -print -quit | grep -q .; then
        rm -f "$thumb"
    fi
done

find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) | while read -r img; do
    name=$(basename "$img")
    thumb="$THUMB_DIR/$name.png"
    if [ ! -f "$thumb" ] || [ "$img" -nt "$thumb" ]; then
        # [0] = first frame only; without it animated gifs expand into one PNG per frame
        magick "${img}[0]" -thumbnail 128x80 "$thumb" &
    fi
done
wait

SELECTED=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) | sort | while read -r img; do
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

echo "$WALLPAPER" > "$STATE_FILE"

killall waybar 2>/dev/null
waybar -c "$HOME/.config/waybar/config-niri" &disown
notify-send "Wallpaper Picker" "Applied: $SELECTED"
