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

DP1="DP-1"
HDMI="HDMI-A-1"

all_on() {
    niri msg action power-on-monitors
    niri msg output "$DP1" on
    niri msg output "$HDMI" on
}

case "${1:-menu}" in
menu)
    choice=$(printf '%s\n' \
        "🖥️ All Monitors Off (blank, any key wakes)" \
        "🖥️ DP-1 Off (disable)" \
        "🖥️ HDMI-A-1 Off (disable)" \
        "💡 All Monitors On" \
        "💡 DP-1 On" \
        "💡 HDMI-A-1 On" \
        "❌ Cancel" | rofi -dmenu -p "Monitors" -i)

    case "$choice" in
    "🖥️ All Monitors Off"*) niri msg action power-off-monitors ;;
    "🖥️ DP-1 Off"*) niri msg output "$DP1" off ;;
    "🖥️ HDMI-A-1 Off"*) niri msg output "$HDMI" off ;;
    "💡 All Monitors On"*) all_on ;;
    "💡 DP-1 On"*) niri msg output "$DP1" on ;;
    "💡 HDMI-A-1 On"*) niri msg output "$HDMI" on ;;
    *) ;;
    esac
    ;;
on)
    all_on
    ;;
esac
