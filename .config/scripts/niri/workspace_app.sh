#!/usr/bin/env bash
set -euo pipefail

mode="focus"
if [ "${1:-}" = "--move" ]; then
    mode="move"
    shift
fi

ws="${1:?usage: workspace_app.sh [--move] <workspace-name> [command...]}"
shift || true

ws_json=$(niri msg -j workspaces)

mapfile -t ids < <(jq -r --arg w "$ws" '.[] | select(.name == $w) | .id' <<<"$ws_json")
if [ "${#ids[@]}" -eq 0 ]; then
    notify-send "workspace_app" "No workspace named '$ws' — is it declared in config.kdl?"
    exit 1
fi
if [ "${#ids[@]}" -gt 1 ]; then
    notify-send "workspace_app" "Several workspaces named '$ws' — un-name the leftover one"
    exit 1
fi
id="${ids[0]}"

if [ "$mode" = "move" ]; then
    niri msg action move-column-to-workspace "$ws" >/dev/null
    exit 0
fi

count=$(niri msg -j windows | jq --argjson id "$id" '[.[] | select(.workspace_id == $id)] | length')

if [ "$count" -eq 0 ]; then
    focused=$(jq -r '.[] | select(.is_focused == true) | .output' <<<"$ws_json")
    home=$(jq -r --arg w "$ws" '.[] | select(.name == $w) | .output' <<<"$ws_json")
    if [ -n "$focused" ] && [ "$focused" != "$home" ]; then
        niri msg action move-workspace-to-monitor --reference "$ws" "$focused" >/dev/null || true
    fi
fi

niri msg action focus-workspace "$ws" >/dev/null

if [ "$count" -eq 0 ] && [ "$#" -gt 0 ]; then
    setsid "$@" >/dev/null 2>&1 &
fi
