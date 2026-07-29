#!/usr/bin/env bash
# Navigate only the PLAIN (unnamed) workspaces, skipping the named app ones.
#
# usage: workspace_nav.sh focus <N>       focus the Nth plain workspace
#        workspace_nav.sh move  <N>       move focused column to it
#        workspace_nav.sh next|prev       focus the next/previous plain one
#        workspace_nav.sh move-next|move-prev
#        workspace_nav.sh up|down         focus within the column, else the
#                                         workspace above/below
#        workspace_nav.sh move-up|move-down  same, moving the window
#
# Why this exists: niri workspace numbers are indices into each output's live
# workspace list, and the named app workspaces (code, github, ...) live in that
# same list — so Mod+3 could land on "discord". The app workspaces are reachable
# by their own Alt+<letter> binds, and should be invisible to number and
# directional navigation.
#
# Everything is scoped to the focused output, matching niri's own per-output
# indices. N beyond the number of plain workspaces clamps to the last one; niri
# always keeps one empty unnamed workspace at the end of each output, so there
# is always at least one target.
set -euo pipefail

action="${1:?usage: workspace_nav.sh focus|move|next|prev|move-next|move-prev|up|down|move-up|move-down [N]}"

# Vertical motion: niri stacks workspaces vertically, so "down" means the next
# window in the column when there is one, and otherwise the workspace below.
# Whether the in-column action did anything is decided by comparing the focused
# window's row before and after — cheaper and more robust than reimplementing
# niri's column arithmetic.
if [ "$action" = "up" ] || [ "$action" = "down" ] || [ "$action" = "move-up" ] || [ "$action" = "move-down" ]; then
    row_of_focused() {
        niri msg -j windows | jq -r '.[] | select(.is_focused == true) | .layout.pos_in_scrolling_layout | "\(.[0]),\(.[1])"'
    }

    before=$(row_of_focused)

    case "$action" in
    up)        niri msg action focus-window-up >/dev/null 2>&1 || true ;;
    down)      niri msg action focus-window-down >/dev/null 2>&1 || true ;;
    move-up)   niri msg action move-window-up >/dev/null 2>&1 || true ;;
    move-down) niri msg action move-window-down >/dev/null 2>&1 || true ;;
    esac

    after=$(row_of_focused)

    if [ -n "$before" ] && [ "$before" != "$after" ]; then
        exit 0 # the in-column move worked
    fi

    # Nowhere to go inside the column: fall through to the workspace above/below,
    # which is the plain-workspace navigation below.
    case "$action" in
    up)        action="prev" ;;
    down)      action="next" ;;
    move-up)   action="move-prev" ;;
    move-down) action="move-next" ;;
    esac
fi

ws_json=$(niri msg -j workspaces)
output=$(jq -r '.[] | select(.is_focused == true) | .output' <<<"$ws_json")

# Indices of the plain workspaces on this output, in list order.
mapfile -t plain < <(jq -r --arg o "$output" '
    [ .[] | select(.output == $o and .name == null) ] | sort_by(.idx) | .[] | .idx
' <<<"$ws_json")

[ "${#plain[@]}" -gt 0 ] || exit 0

# Where the currently focused workspace sits among them (-1 if it is a named one).
current_idx=$(jq -r --arg o "$output" '.[] | select(.output == $o and .is_active == true) | .idx' <<<"$ws_json")
pos=-1
for i in "${!plain[@]}"; do
    if [ "${plain[$i]}" = "$current_idx" ]; then
        pos=$i
        break
    fi
done

target=""

case "$action" in
focus | move)
    n="${2:?need a workspace number}"
    i=$((n - 1))
    [ "$i" -lt 0 ] && i=0
    [ "$i" -ge "${#plain[@]}" ] && i=$((${#plain[@]} - 1))
    target="${plain[$i]}"
    ;;
next | move-next)
    # From a named workspace, "next" means the first plain one.
    if [ "$pos" -lt 0 ]; then
        target="${plain[0]}"
    else
        i=$((pos + 1))
        [ "$i" -ge "${#plain[@]}" ] && i=$((${#plain[@]} - 1))
        target="${plain[$i]}"
    fi
    ;;
prev | move-prev)
    if [ "$pos" -lt 0 ]; then
        target="${plain[0]}"
    else
        i=$((pos - 1))
        [ "$i" -lt 0 ] && i=0
        target="${plain[$i]}"
    fi
    ;;
*)
    echo "unknown action: $action" >&2
    exit 1
    ;;
esac

case "$action" in
focus | next | prev)
    niri msg action focus-workspace "$target"
    ;;
move | move-next | move-prev)
    niri msg action move-column-to-workspace "$target"
    ;;
esac
