#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$(realpath "$0")")/monitors.sh"

all_on() {
    niri msg action power-on-monitors
    niri msg output "$LEFT_MONITOR" on
    niri msg output "$RIGHT_MONITOR" on
}

case "${1:-menu}" in
menu)
    choice=$(printf '%s\n' \
        "🖥️ All Monitors Off" \
        "🖥️ $LEFT_MONITOR Off" \
        "🖥️ $RIGHT_MONITOR Off" \
        "💡 All Monitors On" \
        "💡 $LEFT_MONITOR On" \
        "💡 $RIGHT_MONITOR On" \
        "❌ Cancel" | rofi -dmenu -p "Monitors" -i)

    case "$choice" in
    "🖥️ All Monitors Off"*) niri msg action power-off-monitors ;;
    "🖥️ $LEFT_MONITOR Off"*) niri msg output "$LEFT_MONITOR" off ;;
    "🖥️ $RIGHT_MONITOR Off"*) niri msg output "$RIGHT_MONITOR" off ;;
    "💡 All Monitors On"*) all_on ;;
    "💡 $LEFT_MONITOR On"*) niri msg output "$LEFT_MONITOR" on ;;
    "💡 $RIGHT_MONITOR On"*) niri msg output "$RIGHT_MONITOR" on ;;
    *) ;;
    esac
    ;;
on)
    all_on
    ;;
esac
