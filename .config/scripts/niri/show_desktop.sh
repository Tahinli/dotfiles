#!/bin/bash
set -euo pipefail

STATE_FILE="/tmp/niri_show_desktop"

ws_json=$(niri msg -j workspaces)

ref_of() {
    jq -r 'if .name != null then .name else (.idx | tostring) end' <<<"$1"
}

if [ -f "$STATE_FILE" ]; then
    while IFS=$'\t' read -r out ref; do
        [ -n "$out" ] || continue
        niri msg action focus-monitor "$out" >/dev/null
        niri msg action focus-workspace "$ref" >/dev/null
    done < <(grep -v '^FOCUSED' "$STATE_FILE")

    focused_out=$(grep '^FOCUSED' "$STATE_FILE" | cut -f2)
    [ -n "$focused_out" ] && niri msg action focus-monitor "$focused_out" >/dev/null

    rm -f "$STATE_FILE"
else
    win_json=$(niri msg -j windows)
    focused_out=$(jq -r '.[] | select(.is_focused == true) | .output' <<<"$ws_json")

    : > "$STATE_FILE"
    printf 'FOCUSED\t%s\n' "$focused_out" >> "$STATE_FILE"

    while read -r out; do
        active=$(jq -c --arg o "$out" '.[] | select(.output == $o and .is_active == true)' <<<"$ws_json")
        printf '%s\t%s\n' "$out" "$(ref_of "$active")" >> "$STATE_FILE"
    done < <(jq -r '[.[].output] | unique | .[]' <<<"$ws_json")

    while read -r out; do
        empty_idx=$(jq -r --arg o "$out" --argjson w "$win_json" '
            [ .[]
              | select(.output == $o and .name == null)
              | . as $ws
              | select(([$w[] | select(.workspace_id == $ws.id)] | length) == 0)
            ] | last | .idx // empty' <<<"$ws_json")

        if [ -z "$empty_idx" ]; then
            empty_idx=$(jq -r --arg o "$out" '[.[] | select(.output == $o) | .idx] | max' <<<"$ws_json")
        fi

        niri msg action focus-monitor "$out" >/dev/null
        niri msg action focus-workspace "$empty_idx" >/dev/null
    done < <(jq -r '[.[].output] | unique | .[]' <<<"$ws_json")

    niri msg action focus-monitor "$focused_out" >/dev/null
fi
