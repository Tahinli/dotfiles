#!/bin/bash

source "$(dirname "$0")/monitors.sh"

# DPMS off makes the display drop its link, so niri sees a disconnect and
# destroys that output's empty workspaces. On reconnect the active workspace
# falls back to the first surviving one. Just put every output back on its
# first workspace once the outputs return.
reset_workspaces() {
    for _ in $(seq 1 600); do
        niri msg -j workspaces 2>/dev/null |
            jq -e --arg l "$LEFT_MONITOR" --arg r "$RIGHT_MONITOR" \
                'any(.[]; .output == $l) and any(.[]; .output == $r)' >/dev/null && break
        sleep 1
    done
    sleep 1
    "$(dirname "$0")/show_desktop.sh" >/dev/null 2>&1
}

case "${1:-menu}" in
    --reset)
        reset_workspaces
        exit 0
        ;;
    menu)
        menu=$(echo -e "🖥️ All Monitors Off\n🖥️ $LEFT_MONITOR Off\n🖥️ $RIGHT_MONITOR Off\n💡 All Monitors On\n💡 $LEFT_MONITOR On\n💡 $RIGHT_MONITOR On\n❌ Cancel" | rofi -dmenu -p "Monitors" -i)

        case "$menu" in
            "🖥️ All Monitors Off")
                setsid nohup "$0" --reset >/dev/null 2>&1 &
                niri msg action power-off-monitors
                ;;
            "🖥️ $LEFT_MONITOR Off")
                niri msg output "$LEFT_MONITOR" off
                ;;
            "🖥️ $RIGHT_MONITOR Off")
                niri msg output "$RIGHT_MONITOR" off
                ;;
            "💡 All Monitors On")
                niri msg output "$LEFT_MONITOR" on
                niri msg output "$RIGHT_MONITOR" on
                ;;
            "💡 $LEFT_MONITOR On")
                niri msg output "$LEFT_MONITOR" on
                ;;
            "💡 $RIGHT_MONITOR On")
                niri msg output "$RIGHT_MONITOR" on
                ;;
            "❌ Cancel")
                ;;
        esac
        ;;
    on)
        niri msg output "$LEFT_MONITOR" on
        niri msg output "$RIGHT_MONITOR" on
        ;;
esac
