#!/usr/bin/env bash
set -euo pipefail

action="${1:?usage: workspace_nav.sh focus|move|next|prev|move-next|move-prev|up|down|move-up|move-down [N]}"

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
        exit 0
    fi

    case "$action" in
    up)        action="prev" ;;
    down)      action="next" ;;
    move-up)   action="move-prev" ;;
    move-down) action="move-next" ;;
    esac
fi

ws_json=$(niri msg -j workspaces)
output=$(jq -r '.[] | select(.is_focused == true) | .output' <<<"$ws_json")

mapfile -t plain < <(jq -r --arg o "$output" '
    [ .[] | select(.output == $o and .name == null) ] | sort_by(.idx) | .[] | .idx
' <<<"$ws_json")

[ "${#plain[@]}" -gt 0 ] || exit 0

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
    if [ "$pos" -lt 0 ]; then
        # on a named workspace: nearest unnamed one below it
        for idx in "${plain[@]}"; do
            if [ "$idx" -gt "$current_idx" ]; then
                target="$idx"
                break
            fi
        done
        [ -n "$target" ] || exit 0
    else
        i=$((pos + 1))
        [ "$i" -ge "${#plain[@]}" ] && i=$((${#plain[@]} - 1))
        target="${plain[$i]}"
    fi
    ;;
prev | move-prev)
    if [ "$pos" -lt 0 ]; then
        # on a named workspace: nearest unnamed one above it
        for idx in "${plain[@]}"; do
            if [ "$idx" -lt "$current_idx" ]; then
                target="$idx"
            else
                break
            fi
        done
        [ -n "$target" ] || exit 0
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
