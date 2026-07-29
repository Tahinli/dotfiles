#!/usr/bin/env bash
# Emulates Hyprland's `workspace = N, on-created-empty: <cmd>` for niri.
#
# usage: workspace_app.sh <workspace-name> <command> [args...]
#
# Focuses the named workspace, then launches the command only if that
# workspace currently holds no windows. niri has no on-created-empty, and
# named workspaces declared in the config are persistent (never "created"),
# so the emptiness check is what makes this lazy instead of duplicating apps.
set -euo pipefail

ws="$1"
shift

ws_json=$(niri msg -j workspaces)

id=$(jq -r --arg w "$ws" '.[] | select(.name == $w) | .id' <<<"$ws_json")

if [ -z "$id" ]; then
    notify-send "workspace_app" "No workspace named '$ws' — is it declared in config.kdl?"
    exit 1
fi

# Named workspaces live on whichever output they were created on, and
# focus-workspace jumps focus to THAT output instead of bringing the workspace
# to you. So move it here FIRST, with --reference so the move needs no focus
# change: focusing it on the other monitor and dragging it away afterwards
# leaves that monitor stranded on some unrelated workspace.
here=$(jq -r '.[] | select(.is_focused == true) | .output' <<<"$ws_json")
there=$(jq -r --arg w "$ws" '.[] | select(.name == $w) | .output' <<<"$ws_json")

if [ -n "$here" ] && [ "$here" != "$there" ]; then
    niri msg action move-workspace-to-monitor --reference "$ws" "$here"
fi

niri msg action focus-workspace "$ws"

count=$(niri msg -j windows | jq --argjson id "$id" '[.[] | select(.workspace_id == $id)] | length')

if [ "$count" -eq 0 ]; then
    setsid "$@" >/dev/null 2>&1 &
fi
