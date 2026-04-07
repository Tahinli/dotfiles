#!/bin/bash
# Rofi wallpaper picker — updates hyprpaper, wallust, and waybar

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
THUMB_DIR="$HOME/.cache/wallpaper_thumbs"

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

# Update hyprpaper config and kill both processes
cat > "$HYPRPAPER_CONF" << EOF
splash = false

wallpaper {
    monitor =
    path = $WALLPAPER
    fit_mode = cover
}
EOF

pkill hyprpaper
killall waybar 2>/dev/null

# Run hyprpaper and wallust in parallel
hyprpaper &disown
wallust run -q "$WALLPAPER" &
wait

waybar &disown
notify-send "Wallpaper Picker" "Applied: $SELECTED"
