#!/bin/bash
# Get current playing song from playerctl
if command -v playerctl &> /dev/null; then
    # Check if any player is running
    if playerctl status &> /dev/null; then
        status=$(playerctl status 2>/dev/null)
        artist=$(playerctl metadata artist 2>/dev/null)
        title=$(playerctl metadata title 2>/dev/null)
        duration_us=$(playerctl metadata mpris:length 2>/dev/null)

        # Define cache file for paused position
        POSITION_CACHE="/tmp/playerctl_position_cache"

        # Set icon based on playback status
        if [[ "$status" == "Playing" ]]; then
            icon="▶"
        else
            icon="⏸"
        fi

        # Convert duration from microseconds to MM:SS format
        if [[ -n "$duration_us" ]]; then
            duration_sec=$((duration_us / 1000000))
            minutes=$((duration_sec / 60))
            seconds=$((duration_sec % 60))
            duration=$(printf "%02d:%02d" $minutes $seconds)
        else
            duration=""
        fi

        # Get current position with caching logic
        position=""
        position_us=$(playerctl position 2>/dev/null)

        if [[ "$status" == "Playing" ]]; then
            # When playing, get live position and cache it
            if [[ -n "$position_us" ]]; then
                position_sec=$(printf "%.0f" "$position_us")
                pos_minutes=$((position_sec / 60))
                pos_seconds=$((position_sec % 60))
                position=$(printf "%02d:%02d" $pos_minutes $pos_seconds)
                # Cache the position for when paused
                echo "$position" > "$POSITION_CACHE"
            fi
        else
            # When paused, use cached position if available
            if [[ -f "$POSITION_CACHE" ]]; then
                position=$(cat "$POSITION_CACHE")
            fi
        fi

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
            echo "$icon Music"
        fi
    else
        echo ""
    fi
else
    echo ""
fi
