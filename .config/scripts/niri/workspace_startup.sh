#!/usr/bin/env bash
set -euo pipefail

ws=$(niri msg -j workspaces)
home=$(jq -r '.[] | select(.is_focused == true) | .output' <<<"$ws")

while read -r out; do
    idx=$(jq -r --arg o "$out" '
        [ .[] | select(.output == $o and .name == null) ] | sort_by(.idx) | .[0].idx // empty
    ' <<<"$ws")
    [ -n "$idx" ] || continue
    niri msg action focus-monitor "$out" >/dev/null
    niri msg action focus-workspace "$idx" >/dev/null
done < <(jq -r '[ .[].output ] | unique | .[]' <<<"$ws")

if [ -n "$home" ]; then
    niri msg action focus-monitor "$home" >/dev/null
fi
