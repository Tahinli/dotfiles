#!/bin/bash
# Get current playing song from playerctl with sticky player preference

if ! command -v playerctl &> /dev/null; then
    echo ""
    exit 0
fi

player_list=$(playerctl -l 2>/dev/null)
if [[ -z "$player_list" ]]; then
    echo ""
    exit 0
fi

PREFERRED_FILE="/tmp/playerctl_preferred_player"

# Find first Playing and first Paused player
best_playing=""
best_paused=""
while IFS= read -r player; do
    player_status=$(playerctl -p "$player" status 2>/dev/null)
    if [[ "$player_status" == "Playing" && -z "$best_playing" ]]; then
        best_playing="$player"
    elif [[ "$player_status" == "Paused" && -z "$best_paused" ]]; then
        best_paused="$player"
    fi
done <<< "$player_list"

# Sticky player logic: prefer current player to avoid flickering
preferred=""
if [[ -f "$PREFERRED_FILE" ]]; then
    preferred=$(cat "$PREFERRED_FILE")
    pref_status=$(playerctl -p "$preferred" status 2>/dev/null)
    if [[ "$pref_status" != "Playing" && "$pref_status" != "Paused" ]]; then
        preferred=""
        pref_status=""
    fi
fi

# Choose player:
# - If preferred is still Playing, keep it
# - If preferred is Paused but something else is Playing, switch
# - Otherwise fall back to best available
chosen=""
if [[ -n "$preferred" ]]; then
    if [[ "$pref_status" == "Playing" ]]; then
        chosen="$preferred"
    elif [[ -n "$best_playing" ]]; then
        chosen="$best_playing"
    else
        chosen="$preferred"
    fi
else
    chosen="${best_playing:-$best_paused}"
fi

if [[ -z "$chosen" ]]; then
    echo ""
    exit 0
fi

echo "$chosen" > "$PREFERRED_FILE"

# Fetch ALL metadata in a single playerctl call
info=$(playerctl -p "$chosen" metadata --format '{{status}}	{{artist}}	{{title}}	{{mpris:length}}	{{position}}' 2>/dev/null)

if [[ -z "$info" ]]; then
    echo ""
    exit 0
fi

IFS=$'\t' read -r status artist title duration_us position_us <<< "$info"

if [[ "$status" == "Stopped" ]]; then
    echo ""
    exit 0
fi

# Set icon based on playback status
if [[ "$status" == "Playing" ]]; then
    icon="▶"
else
    icon="⏸"
fi

# Convert duration from microseconds to MM:SS
duration=""
if [[ -n "$duration_us" && "$duration_us" -gt 0 ]] 2>/dev/null; then
    duration_sec=$((duration_us / 1000000))
    minutes=$((duration_sec / 60))
    seconds=$((duration_sec % 60))
    duration=$(printf "%02d:%02d" $minutes $seconds)
fi

# Get position with caching for paused state
POSITION_CACHE="/tmp/playerctl_position_cache_${chosen}"
position=""
if [[ "$status" == "Playing" ]]; then
    if [[ -n "$position_us" && "$position_us" -gt 0 ]] 2>/dev/null; then
        position_sec=$((position_us / 1000000))
        pos_minutes=$((position_sec / 60))
        pos_seconds=$((position_sec % 60))
        position=$(printf "%02d:%02d" $pos_minutes $pos_seconds)
        echo "$position" > "$POSITION_CACHE"
    fi
else
    if [[ -f "$POSITION_CACHE" ]]; then
        position=$(cat "$POSITION_CACHE")
    fi
fi

# Escape ampersands for waybar markup
artist="${artist//&/&amp;}"
title="${title//&/&amp;}"

if [[ -n "$artist" && -n "$title" && -n "$duration" && -n "$position" ]]; then
    echo "$icon $artist - $title ($position / $duration)"
elif [[ -n "$artist" && -n "$title" && -n "$duration" ]]; then
    echo "$icon $artist - $title ($duration)"
elif [[ -n "$title" && -n "$duration" && -n "$position" ]]; then
    echo "$icon $title ($position / $duration)"
elif [[ -n "$title" && -n "$duration" ]]; then
    echo "$icon $title ($duration)"
elif [[ -n "$artist" && -n "$title" ]]; then
    echo "$icon $artist - $title"
elif [[ -n "$title" ]]; then
    echo "$icon $title"
else
    echo "$icon Something's Playing"
fi
