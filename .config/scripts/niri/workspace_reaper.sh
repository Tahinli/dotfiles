#!/usr/bin/env bash
# Un-names app workspaces once they are empty, so niri reaps them.
#
# Runs for the whole session (spawn-at-startup in config.kdl). Follows
# `niri msg event-stream` rather than polling, so it is idle unless windows or
# workspaces actually change.
#
# Why: a named workspace is never reaped, whether the name came from a config
# `workspace "..."` node or from set-workspace-name at runtime. The app
# workspaces are named on launch by workspace_app.sh; without this they would
# pile up empty exactly as the declared ones did.
#
# Only names listed in app_workspaces.sh are touched, so hand-named workspaces
# survive.
set -uo pipefail

. "$(dirname "$(realpath "$0")")/app_workspaces.sh"

# A workspace named by workspace_app.sh sits empty until the app maps its window,
# and reaping it in that gap would drop the name the app was launched under. The
# marker file it leaves means "not populated yet, hands off".
#
# The marker is cleared as soon as the workspace holds a window, so the NEXT time
# it goes empty it is reaped at once. A plain timer would not do: if the app is
# closed while the timer is still running, that close event gets skipped and no
# further event arrives to retry.
#
# GRACE_SECONDS is only a backstop for a launch that never produced a window at
# all (crash, wrong command). Flatpak cold starts are slow, hence the size.
GRACE_SECONDS=60
GRACE_DIR="${XDG_RUNTIME_DIR:-/tmp}/niri-ws-grace"

in_grace() {
    local marker="$GRACE_DIR/$1" age
    [ -f "$marker" ] || return 1
    age=$(( $(date +%s) - $(stat -c %Y "$marker") ))
    if [ "$age" -lt "$GRACE_SECONDS" ]; then
        return 0
    fi
    rm -f "$marker"
    return 1
}

reap() {
    local ws_json win_json name
    ws_json=$(niri msg -j workspaces 2>/dev/null) || return 0
    win_json=$(niri msg -j windows 2>/dev/null) || return 0

    # Any named workspace that now holds windows has served its purpose: drop the
    # marker so emptying it later reaps immediately.
    while read -r name; do
        [ -n "$name" ] && rm -f "$GRACE_DIR/$name"
    done < <(jq -r --argjson w "$win_json" '
        .[]
        | select(.name != null)
        | . as $ws
        | select(([$w[] | select(.workspace_id == $ws.id)] | length) > 0)
        | .name
    ' <<<"$ws_json")

    # Named workspaces holding no windows.
    while read -r name; do
        [ -n "$name" ] || continue
        is_app_workspace "$name" || continue
        in_grace "$name" && continue
        # The reference is POSITIONAL here. set-workspace-name takes --workspace
        # and move-workspace-to-monitor takes --reference, but this one does not.
        niri msg action unset-workspace-name "$name" >/dev/null 2>&1 || true
    done < <(jq -r --argjson w "$win_json" '
        .[]
        | select(.name != null)
        | . as $ws
        | select(([$w[] | select(.workspace_id == $ws.id)] | length) == 0)
        | .name
    ' <<<"$ws_json")
}

# Sweep once at startup: workspaces can be left named and empty by a previous
# session, a config reload, or a crash of this script.
reap

# Any window or workspace event. Matching loosely on purpose: niri emits
# WindowOpenedOrChanged (singular) when a window maps and WindowsChanged (plural)
# only for the bulk snapshot, so a narrow list missed the moment a workspace
# became populated — which is exactly when the grace marker must be dropped.
# Ignored by omission: ConfigLoaded, KeyboardLayoutsChanged, OverviewOpenedOrClosed,
# CastsChanged.
niri msg -j event-stream 2>/dev/null | while read -r line; do
    case "$line" in
    *Window* | *Workspace*)
        reap
        ;;
    esac
done
