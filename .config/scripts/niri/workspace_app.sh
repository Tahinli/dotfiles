#!/usr/bin/env bash
# Emulates Hyprland's `workspace = N, on-created-empty: <cmd>` for niri.
#
# usage: workspace_app.sh <workspace-name> <command> [args...]
#        workspace_app.sh --move <workspace-name>
#
# Behaviour:
#   * workspace already exists (app is running) -> just focus it. It stays on the
#     monitor it was launched on; the key moves FOCUS there rather than dragging
#     the workspace to the monitor you happen to be on.
#   * workspace does not exist -> take the trailing empty workspace of the
#     focused monitor, name it, and launch the app there.
#
# The workspaces are deliberately NOT declared in config.kdl: a declared
# `workspace "name"` node is immortal, so eight empty workspaces would always be
# present. Naming happens here and workspace_reaper.sh un-names an app workspace
# once it empties, after which niri reaps it.
set -euo pipefail

. "$(dirname "$(realpath "$0")")/app_workspaces.sh"

mode="focus"
if [ "${1:-}" = "--move" ]; then
    mode="move"
    shift
fi

ws="${1:?usage: workspace_app.sh [--move] <workspace-name> [command...]}"
shift || true

ws_json=$(niri msg -j workspaces)
exists=$(jq -r --arg w "$ws" '[.[] | select(.name == $w)] | length' <<<"$ws_json")

if [ "$exists" = "0" ]; then
    # Claim the last empty unnamed workspace on this monitor. niri always keeps
    # one at the end of every output, so there is something to claim.
    output=$(jq -r '.[] | select(.is_focused == true) | .output' <<<"$ws_json")
    win_json=$(niri msg -j windows)

    idx=$(jq -r --arg o "$output" --argjson w "$win_json" '
        [ .[]
          | select(.output == $o and .name == null)
          | . as $ws
          | select(([$w[] | select(.workspace_id == $ws.id)] | length) == 0)
        ] | last | .idx // empty' <<<"$ws_json")

    if [ -z "$idx" ]; then
        notify-send "workspace_app" "No empty workspace free on $output for '$ws'"
        exit 1
    fi

    # A freshly named workspace is still empty until the app maps its window,
    # and workspace_reaper.sh would un-name it in that gap. The marker tells the
    # reaper to leave this one alone for a while; see GRACE_SECONDS there.
    mkdir -p "${XDG_RUNTIME_DIR:-/tmp}/niri-ws-grace"
    : > "${XDG_RUNTIME_DIR:-/tmp}/niri-ws-grace/$ws"

    niri msg action set-workspace-name --workspace "$idx" "$ws" >/dev/null
fi

if [ "$mode" = "move" ]; then
    niri msg action move-column-to-workspace "$ws" >/dev/null
    exit 0
fi

niri msg action focus-workspace "$ws" >/dev/null

# Launch only when the workspace holds nothing, so a second press is "go there"
# rather than a duplicate app.
id=$(niri msg -j workspaces | jq -r --arg w "$ws" '.[] | select(.name == $w) | .id')
count=$(niri msg -j windows | jq --argjson id "$id" '[.[] | select(.workspace_id == $id)] | length')

if [ "$count" -eq 0 ] && [ "$#" -gt 0 ]; then
    setsid "$@" >/dev/null 2>&1 &
fi
