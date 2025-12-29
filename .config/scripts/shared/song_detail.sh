#!/bin/bash
# Get current playing song from playerctl, prioritizing the most recently active player

if command -v playerctl &> /dev/null; then
    # Check if any player is running
    if playerctl status &> /dev/null; then
        # Get list of all players and find the one with most recent activity
        player_list=$(playerctl -l 2>/dev/null)

        if [[ -z "$player_list" ]]; then
            echo ""
            exit 0
        fi

        # Track which player has the most recent activity
        most_recent_player=""
        most_recent_time=0

        while IFS= read -r player; do
            player_status=$(playerctl -p "$player" status 2>/dev/null)

            # Only consider players that are Playing or Paused
            if [[ "$player_status" == "Playing" ]] || [[ "$player_status" == "Paused" ]]; then
                # Get the last activity time for this player
                activity_cache="/tmp/playerctl_activity_${player}"
                current_time=$(date +%s)

                # Always update timestamp for any Playing or Paused player
                # This ensures we track when a player was last active (Playing or just paused)
                echo "$current_time" > "$activity_cache"

                # Compare timestamps to find most recent
                if [[ $current_time -gt $most_recent_time ]]; then
                    most_recent_time=$current_time
                    most_recent_player="$player"
                fi
            fi
        done <<< "$player_list"

        # If no active player found, exit
        if [[ -z "$most_recent_player" ]]; then
            echo ""
            exit 0
        fi

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
