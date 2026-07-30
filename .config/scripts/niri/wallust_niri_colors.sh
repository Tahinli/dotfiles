#!/bin/bash
set -euo pipefail

CONFIG="$HOME/.config/niri/config.kdl"
COLORS="$HOME/.cache/wallust/niri-colors.sh"
MARKER="// WALLUST-GRADIENT"

[ -f "$CONFIG" ] || exit 0
[ -f "$COLORS" ] || exit 0

. "$COLORS"

FROM="${NIRI_BORDER_FROM#\#}"
TO="${NIRI_BORDER_TO#\#}"

if [ -z "$FROM" ] || [ -z "$TO" ]; then
    exit 0
fi

grep -qF "$MARKER" "$CONFIG" || exit 0

awk -v marker="$MARKER" -v from="#$FROM" -v to="#$TO" '
    hit {
        match($0, /^[ \t]*/)
        indent = substr($0, 1, RLENGTH)
        printf "%sactive-gradient from=\"%s\" to=\"%s\" angle=90 in=\"oklch\"\n", indent, from, to
        hit = 0
        next
    }
    { print }
    index($0, marker) { hit = 1 }
' "$CONFIG" > "$CONFIG.wallust-tmp" && mv "$CONFIG.wallust-tmp" "$CONFIG"
