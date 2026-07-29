#!/usr/bin/env bash
# Rofi monitor chooser for niri. Port of ~/.config/scripts/hyprland/toggle_monitors.sh
#
# usage: toggle_monitors.sh [menu|on]
#
# niri difference worth knowing: there is no per-output DPMS. `power-off-monitors`
# blanks EVERY output and any input wakes them back up, while `niri msg output X off`
# genuinely disables one output — windows on it move away, and only `... on` (or the
# `on` argument here, bound to Super+Shift+M) brings it back. So the single-monitor
# entries below disable rather than blank.
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
        "🖥️ All Monitors Off (blank, any key wakes)" \
        "🖥️ $LEFT_MONITOR Off (disable)" \
        "🖥️ $RIGHT_MONITOR Off (disable)" \
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
