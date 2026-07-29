#!/usr/bin/env bash
# Emulates Hyprland's `workspace = N, on-created-empty: <cmd>` for niri.
#
# usage: workspace_app.sh <workspace-name> <command> [args...]
#
# Focuses the named workspace, then launches the command only if that workspace
# currently holds no windows. niri has no on-created-empty, and named workspaces
# declared in the config are persistent (never "created"), so the emptiness check
# is what makes this lazy instead of duplicating apps.
#
# An app's workspace sticks to the monitor it was first launched on. Pressing the
# key again moves FOCUS there rather than pulling the workspace to the monitor
# you happen to be on.
set -euo pipefail

ws="$1"
shift

ws_json=$(niri msg -j workspaces)

id=$(jq -r --arg w "$ws" '.[] | select(.name == $w) | .id' <<<"$ws_json")

if [ -z "$id" ]; then
    notify-send "workspace_app" "No workspace named '$ws' — is it declared in config.kdl?"
    exit 1
fi

count=$(niri msg -j windows | jq --argjson id "$id" '[.[] | select(.workspace_id == $id)] | length')

here=$(jq -r '.[] | select(.is_focused == true) | .output' <<<"$ws_json")
there=$(jq -r --arg w "$ws" '.[] | select(.name == $w) | .output' <<<"$ws_json")

# The app's workspace HOME is the monitor it was first launched on, and it stays
# there: pressing the key again just sends focus to that monitor instead of
# dragging the workspace over. Only an empty (never-used) workspace gets moved,
# so a first launch happens where you are.
#
# --reference avoids a focus change for the move: focusing it on the other
# monitor and dragging it away afterwards leaves that monitor stranded on some
# unrelated workspace.
if [ "$count" -eq 0 ] && [ -n "$here" ] && [ "$here" != "$there" ]; then
    niri msg action move-workspace-to-monitor --reference "$ws" "$here"
fi

niri msg action focus-workspace "$ws"

if [ "$count" -eq 0 ]; then
    setsid "$@" >/dev/null 2>&1 &
fi
