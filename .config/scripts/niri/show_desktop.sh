#!/bin/bash
# Show-desktop toggle for niri. Port of ~/.config/scripts/hyprland/show_desktop.sh
#
# Same idea as the Hyprland version: remember what each output is showing, send
# every output to an empty workspace, and restore on the second press. niri
# always keeps one empty workspace at the end of each output's list, so there is
# no need for the dedicated 998/999 dummy workspaces Hyprland needed.
#
# Workspaces are referenced by name when they have one and by index otherwise,
# because niri workspace indices shift as workspaces come and go.
set -euo pipefail

STATE_FILE="/tmp/niri_show_desktop"

ws_json=$(niri msg -j workspaces)

# Reference used to focus a workspace again later: prefer the name, else index.
ref_of() { # $1 = jq object
    jq -r 'if .name != null then .name else (.idx | tostring) end' <<<"$1"
}

if [ -f "$STATE_FILE" ]; then
    # Restore. Focus each output, put back what it was showing, then return
    # focus to the output that had it before.
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

    # Record the active workspace of every output.
    while read -r out; do
        active=$(jq -c --arg o "$out" '.[] | select(.output == $o and .is_active == true)' <<<"$ws_json")
        printf '%s\t%s\n' "$out" "$(ref_of "$active")" >> "$STATE_FILE"
    done < <(jq -r '[.[].output] | unique | .[]' <<<"$ws_json")

    # Send every output to an empty workspace of its own.
    while read -r out; do
        # Unnamed only: the named workspaces are the app ones (code, discord,
        # ...), and landing on an empty "github" is not "show desktop".
        empty_idx=$(jq -r --arg o "$out" --argjson w "$win_json" '
            [ .[]
              | select(.output == $o and .name == null)
              | . as $ws
              | select(([$w[] | select(.workspace_id == $ws.id)] | length) == 0)
            ] | last | .idx // empty' <<<"$ws_json")

        # Fall back to the highest index on that output, which niri keeps empty.
        if [ -z "$empty_idx" ]; then
            empty_idx=$(jq -r --arg o "$out" '[.[] | select(.output == $o) | .idx] | max' <<<"$ws_json")
        fi

        niri msg action focus-monitor "$out" >/dev/null
        niri msg action focus-workspace "$empty_idx" >/dev/null
    done < <(jq -r '[.[].output] | unique | .[]' <<<"$ws_json")

    niri msg action focus-monitor "$focused_out" >/dev/null
fi
