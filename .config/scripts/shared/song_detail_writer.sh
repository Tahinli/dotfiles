#!/bin/bash
# Single-source writer: poll playerctl, write the formatted song-detail line
# to /tmp/song_detail_last so every waybar bar can stream it via `tail -F`
# without two scripts racing on shared /tmp state.

OUTPUT_FILE="/tmp/song_detail_last"
POSITION_CACHE_PREFIX="/tmp/playerctl_position_cache_"
ACTIVITY_PREFIX="/tmp/playerctl_activity_"
INTERVAL=1

atomic_write() {
    local target="$1" content="$2" tmp
    tmp=$(mktemp --tmpdir=/tmp song_detail.XXXXXX) || return 1
    printf '%s\n' "$content" > "$tmp" && mv -f "$tmp" "$target"
}

last_emit="__init__"
emit() {
    local out="$1"
    [[ "$out" == "$last_emit" ]] && return
    atomic_write "$OUTPUT_FILE" "$out" && last_emit="$out"
}

# Ensure file exists immediately so `tail -F` doesn't sit empty on startup.
atomic_write "$OUTPUT_FILE" ""

while true; do
    if ! command -v playerctl &>/dev/null; then
        emit ""
        sleep "$INTERVAL"
        continue
    fi

    player_list=$(playerctl -l 2>/dev/null)
    if [[ -z "$player_list" ]]; then
        emit ""
        sleep "$INTERVAL"
        continue
    fi

    now=$(date +%s)
    sanitize() { printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'; }

    best_playing=""
    best_playing_ts=0
    best_paused=""
    best_paused_ts=0
    while IFS= read -r player; do
        [[ -z "$player" ]] && continue
        player_status=$(playerctl -p "$player" status 2>/dev/null)
        act_file="${ACTIVITY_PREFIX}$(sanitize "$player")"
        if [[ "$player_status" == "Playing" ]]; then
            atomic_write "$act_file" "$now"
            ts="$now"
            if (( ts > best_playing_ts )); then
                best_playing_ts="$ts"
                best_playing="$player"
            fi
        elif [[ "$player_status" == "Paused" ]]; then
            ts=0
            [[ -f "$act_file" ]] && ts=$(cat "$act_file" 2>/dev/null) && [[ -z "$ts" ]] && ts=0
            if (( ts > best_paused_ts )); then
                best_paused_ts="$ts"
                best_paused="$player"
            fi
        fi
    done <<< "$player_list"

    chosen="${best_playing:-$best_paused}"

    if [[ -z "$chosen" ]]; then
        emit ""
        sleep "$INTERVAL"
        continue
    fi

    info=$(playerctl -p "$chosen" metadata --format '{{status}}	{{artist}}	{{title}}	{{mpris:length}}	{{position}}' 2>/dev/null)
    if [[ -z "$info" ]]; then
        emit ""
        sleep "$INTERVAL"
        continue
    fi

    IFS=$'\t' read -r status artist title duration_us position_us <<< "$info"

    if [[ "$status" == "Stopped" ]]; then
        emit ""
        sleep "$INTERVAL"
        continue
    fi

    if [[ "$status" == "Playing" ]]; then
        icon="▶"
    else
        icon="⏸"
    fi

    duration=""
    if [[ -n "$duration_us" && "$duration_us" -gt 0 ]] 2>/dev/null; then
        duration_sec=$((duration_us / 1000000))
        minutes=$((duration_sec / 60))
        seconds=$((duration_sec % 60))
        duration=$(printf "%02d:%02d" $minutes $seconds)
    fi

    POSITION_CACHE="${POSITION_CACHE_PREFIX}$(sanitize "$chosen")"
    position=""
    if [[ "$status" == "Playing" ]]; then
        if [[ -n "$position_us" && "$position_us" -gt 0 ]] 2>/dev/null; then
            position_sec=$((position_us / 1000000))
            pos_minutes=$((position_sec / 60))
            pos_seconds=$((position_sec % 60))
            position=$(printf "%02d:%02d" $pos_minutes $pos_seconds)
            atomic_write "$POSITION_CACHE" "$position"
        fi
    else
        if [[ -f "$POSITION_CACHE" ]]; then
            position=$(cat "$POSITION_CACHE")
        fi
    fi

    artist="${artist//&/&amp;}"
    title="${title//&/&amp;}"

    if [[ -n "$artist" && -n "$title" && -n "$duration" && -n "$position" ]]; then
        out="$icon $artist - $title ($position / $duration)"
    elif [[ -n "$artist" && -n "$title" && -n "$duration" ]]; then
        out="$icon $artist - $title ($duration)"
    elif [[ -n "$title" && -n "$duration" && -n "$position" ]]; then
        out="$icon $title ($position / $duration)"
    elif [[ -n "$title" && -n "$duration" ]]; then
        out="$icon $title ($duration)"
    elif [[ -n "$artist" && -n "$title" ]]; then
        out="$icon $artist - $title"
    elif [[ -n "$title" ]]; then
        out="$icon $title"
    else
        out="$icon Something's Playing"
    fi

    emit "$out"
    sleep "$INTERVAL"
done
