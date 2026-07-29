#!/bin/bash
# Rewrite niri's border gradient from the current wallust palette.
#
# Runs as a wallust hook (see [hooks] in ~/.config/wallust/wallust.toml), so it
# fires on every `wallust run`, i.e. on every wallpaper change.
#
# niri has no `include` directive, so the colors cannot be generated into a
# separate file and pulled in — the line has to be edited inside config.kdl
# itself. The line immediately following the "// WALLUST-GRADIENT" marker is
# replaced wholesale. niri watches its config and reloads on write, so the
# border updates live.
#
# Safe to run under Hyprland too: it only edits a file. niri picks up the new
# colors whenever it next runs.
set -euo pipefail

CONFIG="$HOME/.config/niri/config.kdl"
SEQUENCES="$HOME/.cache/wallust/sequences"
MARKER="// WALLUST-GRADIENT"

[ -f "$CONFIG" ] || exit 0
[ -f "$SEQUENCES" ] || exit 0

# wallust writes the palette as terminal OSC sequences: ]4;<n>;#RRGGBB
color_at() {
    grep -oP "\]4;$1;#\K[0-9A-Fa-f]{6}" "$SEQUENCES" | head -1
}

FROM=$(color_at 4)
TO=$(color_at 6)

if [ -z "$FROM" ] || [ -z "$TO" ]; then
    exit 0
fi

grep -qF "$MARKER" "$CONFIG" || exit 0

# Replace the line after the marker, preserving its indentation.
awk -v marker="$MARKER" -v from="#$FROM" -v to="#$TO" '
    hit {
        match($0, /^[ \t]*/)
        indent = substr($0, 1, RLENGTH)
        printf "%sactive-gradient from=\"%s\" to=\"%s\" angle=90 in=\"oklch longer hue\"\n", indent, from, to
        hit = 0
        next
    }
    { print }
    index($0, marker) { hit = 1 }
' "$CONFIG" > "$CONFIG.wallust-tmp" && mv "$CONFIG.wallust-tmp" "$CONFIG"
