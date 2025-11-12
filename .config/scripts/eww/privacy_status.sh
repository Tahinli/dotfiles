#!/bin/bash

# Privacy indicator script for eww bar
# Usage: privacy.sh [status|details]
# status  - Returns just the icons (for bar display)
# details - Returns detailed info (for tooltip)

# Shared detection logic
detect_audio_output() {
    if command -v pactl &> /dev/null; then
        if pactl list sink-inputs 2>/dev/null | grep -q "Corked: no"; then
            return 0
        fi
    fi
    return 1
}

detect_audio_input() {
    if command -v pactl &> /dev/null; then
        if pactl list source-outputs 2>/dev/null | grep -q "Corked: no"; then
            return 0
        fi
    fi
    return 1
}

detect_screen_sharing() {
    if command -v pw-dump &> /dev/null; then
        if pw-dump 2>/dev/null | grep -q "xdg-desktop-portal.*capture"; then
            return 0
        fi
    fi
    return 1
}

detect_camera() {
    if command -v lsof &> /dev/null; then
        # Check if any /dev/video* devices are open
        if lsof /dev/video* 2>/dev/null | grep -qv "COMMAND"; then
            return 0
        fi
    fi
    return 1
}

get_output_apps() {
    if command -v pactl &> /dev/null; then
        pactl list sink-inputs 2>/dev/null | grep -oP '(?<=application\.name = ")[^"]*' | sort -u | paste -sd ', ' -
    fi
}

get_input_apps() {
    if command -v pactl &> /dev/null; then
        pactl list source-outputs 2>/dev/null | grep -oP '(?<=application\.name = ")[^"]*' | sort -u | paste -sd ', ' -
    fi
}

get_screen_app() {
    if command -v pw-dump &> /dev/null; then
        if pw-dump 2>/dev/null | jq -r '.[] | select(.info.props["application.name"] != null) | .info.props["application.name"]' 2>/dev/null | grep -q "Brave"; then
            echo "Brave"
        elif pw-dump 2>/dev/null | jq -r '.[] | select(.info.props["application.name"] != null) | .info.props["application.name"]' 2>/dev/null | grep -q "Zen"; then
            echo "Zen"
        fi
    fi
}

get_camera_apps() {
    if command -v lsof &> /dev/null; then
        lsof /dev/video* 2>/dev/null | awk 'NR>1 {print $1}' | sort -u | paste -sd ', ' -
    fi
}

# Show status (just icons for bar)
show_status() {
    output=""

    if detect_audio_output; then
        output+="⌣ "
    fi

    if detect_audio_input; then
        output+="⌢ "
    fi

    if detect_screen_sharing; then
        output+="⊞ "
    fi

    if detect_camera; then
        output+="⊙ "
    fi

    echo "$output" | xargs
}

# Show details (for tooltip)
show_details() {
    lines=()

    if detect_audio_output; then
        output_apps=$(get_output_apps)
        if [ -n "$output_apps" ]; then
            lines+=("⌣ Playing: $output_apps")
        fi
    fi

    if detect_audio_input; then
        input_apps=$(get_input_apps)
        if [ -n "$input_apps" ]; then
            lines+=("⌢ Recording: $input_apps")
        fi
    fi

    if detect_screen_sharing; then
        screen_app=$(get_screen_app)
        if [ -n "$screen_app" ]; then
            lines+=("⊞ Sharing: $screen_app")
        fi
    fi

    if detect_camera; then
        camera_apps=$(get_camera_apps)
        if [ -n "$camera_apps" ]; then
            lines+=("⊙ Camera: $camera_apps")
        fi
    fi

    printf "%s\n" "${lines[@]}"
}

# Main logic
case "${1:-status}" in
    status)
        show_status
        ;;
    details)
        show_details
        ;;
    *)
        show_status
        ;;
esac
