#!/bin/bash
# Forward playerctl commands to the ACTIVE player: the one currently Playing,
# else the most recently Playing (now Paused) one — the same selection
# song_detail_writer.sh makes for the waybar display, so clicks hit the
# player the bar is showing instead of the first in `playerctl -l` order.
#
# Usage: playerctl-active.sh play-pause|stop|next|previous|status|metadata ...

ACTIVITY_PREFIX="/tmp/playerctl_activity_"
sanitize() { printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'; }

chosen=""
fallback=""
fallback_ts=0
while IFS= read -r player; do
    [[ -z "$player" ]] && continue
    status=$(playerctl -p "$player" status 2>/dev/null) || continue
    if [[ "$status" == "Playing" ]]; then
        chosen="$player"
        break
    elif [[ "$status" == "Paused" ]]; then
        ts=0
        act_file="${ACTIVITY_PREFIX}$(sanitize "$player")"
        [[ -f "$act_file" ]] && ts=$(cat "$act_file" 2>/dev/null) && [[ -z "$ts" ]] && ts=0
        if (( ts > fallback_ts )); then
            fallback_ts="$ts"
            fallback="$player"
        fi
    fi
done < <(playerctl -l 2>/dev/null)

chosen="${chosen:-$fallback}"
[[ -z "$chosen" ]] && exit 1

exec playerctl -p "$chosen" "$@"
