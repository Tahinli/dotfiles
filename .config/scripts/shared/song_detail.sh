#!/bin/bash
# Get current playing song from playerctl with sticky player preference

if command -v playerctl &> /dev/null; then
    # Check if any player is running
    if playerctl status &> /dev/null; then
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
            # Drop preferred if it's gone or stopped
            if [[ "$pref_status" != "Playing" && "$pref_status" != "Paused" ]]; then
                preferred=""
            fi
        fi

        # Choose player:
        # - If preferred is still Playing, keep it (prevents flickering)
        # - If preferred is Paused but something else is Playing, switch
        # - Otherwise fall back to best available
        chosen=""
        if [[ -n "$preferred" ]]; then
            pref_status=$(playerctl -p "$preferred" status 2>/dev/null)
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

        most_recent_player="$chosen"
        status=$(playerctl -p "$most_recent_player" status 2>/dev/null)

        # Exit if media is stopped
        if [[ "$status" == "Stopped" ]]; then
            echo ""
            exit 0
        fi

        artist=$(playerctl -p "$most_recent_player" metadata artist 2>/dev/null)
        title=$(playerctl -p "$most_recent_player" metadata title 2>/dev/null)
        duration_us=$(playerctl -p "$most_recent_player" metadata mpris:length 2>/dev/null)

        # Define cache file for paused position
        POSITION_CACHE="/tmp/playerctl_position_cache_${most_recent_player}"

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
        position_us=$(playerctl -p "$most_recent_player" position 2>/dev/null)

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

        # Escape special characters for waybar markup compatibility
        artist_escaped="${artist//&/&amp;}"
        title_escaped="${title//&/&amp;}"

        if [[ -n "$artist" && -n "$title" && -n "$duration" && -n "$position" ]]; then
            echo "$icon $artist_escaped - $title_escaped ($position / $duration)"
        elif [[ -n "$artist" && -n "$title" && -n "$duration" ]]; then
            echo "$icon $artist_escaped - $title_escaped ($duration)"
        elif [[ -n "$title" && -n "$duration" && -n "$position" ]]; then
            echo "$icon $title_escaped ($position / $duration)"
        elif [[ -n "$title" && -n "$duration" ]]; then
            echo "$icon $title_escaped ($duration)"
        elif [[ -n "$artist" && -n "$title" ]]; then
            echo "$icon $artist_escaped - $title_escaped"
        elif [[ -n "$title" ]]; then
            echo "$icon $title_escaped"
        else
            echo "$icon Something's Playing"
        fi
    else
        echo ""
    fi
else
    echo ""
fi
