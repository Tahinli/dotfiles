#!/bin/bash

source "$(dirname "$0")/monitors.sh"

case "${1:-menu}" in
    menu)
        menu=$(echo -e "🖥️ All Monitors Off\n🖥️ $LEFT_MONITOR Off\n🖥️ $RIGHT_MONITOR Off\n💡 All Monitors On\n💡 $LEFT_MONITOR On\n💡 $RIGHT_MONITOR On\n❌ Cancel" | rofi -dmenu -p "Monitors" -i)

        case "$menu" in
            "🖥️ All Monitors Off")
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
