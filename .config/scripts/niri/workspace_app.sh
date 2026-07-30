#!/usr/bin/env bash
# Focus an app workspace, launching the app the first time.
#
# usage: workspace_app.sh <workspace-name> <command> [args...]
#        workspace_app.sh --move <workspace-name>
#
# Behaviour:
#   * workspace holds windows (app is running) -> just focus it. It stays on the
#     monitor it was launched on; the key moves FOCUS there rather than dragging
#     the workspace to the monitor you happen to be on.
#   * workspace is empty (app not running) -> pull it to the focused monitor,
#     focus it, and launch the app there.
#
# The workspaces are DECLARED in config.kdl, so they always exist and niri never
# reaps them. That is what removed the naming step, the grace marker files and
# workspace_reaper.sh: with a permanent workspace, "is the app running" is just
# "does its workspace hold a window", which is one stateless query per keypress
# instead of a daemon following the IPC event stream.
set -euo pipefail

mode="focus"
if [ "${1:-}" = "--move" ]; then
    mode="move"
    shift
fi

ws="${1:?usage: workspace_app.sh [--move] <workspace-name> [command...]}"
shift || true

ws_json=$(niri msg -j workspaces)

# Resolved before the --move branch so both modes fail loudly rather than letting
# niri exit non-zero into a keybind, where nothing would be shown at all.
# Two ids means two workspaces carry the name — a leftover runtime name next to
# the declared one — which every jq below would then choke on.
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
    # Empty, so the app is not running: bring the workspace to the monitor in use
    # before focusing, so the app opens where you are. move-workspace-to-monitor
    # takes --reference; the positional argument is the OUTPUT.
    focused=$(jq -r '.[] | select(.is_focused == true) | .output' <<<"$ws_json")
    home=$(jq -r --arg w "$ws" '.[] | select(.name == $w) | .output' <<<"$ws_json")
    # || true: a failed move must not take the focus and the launch down with it
    # under `set -e`. Worst case the app opens on the workspace's own monitor.
    if [ -n "$focused" ] && [ "$focused" != "$home" ]; then
        niri msg action move-workspace-to-monitor --reference "$ws" "$focused" >/dev/null || true
    fi
fi

niri msg action focus-workspace "$ws" >/dev/null

# Launch only when the workspace holds nothing, so a second press is "go there"
# rather than a duplicate app.
if [ "$count" -eq 0 ] && [ "$#" -gt 0 ]; then
    setsid "$@" >/dev/null 2>&1 &
fi
