#!/bin/bash

# Toggle monitors off via rofi, re-enable with keybinding

DP1_CONFIG="DP-1, 2560x1440@180, 0x0, 1, bitdepth, 10"
HDMI_CONFIG="HDMI-A-1, 1920x1080@75, 2560x0, 1, bitdepth, 10"

case "${1:-menu}" in
    menu)
        menu=$(echo -e "🖥️ All Monitors Off\n🖥️ DP-1 Off\n🖥️ HDMI-A-1 Off\n❌ Cancel" | rofi -dmenu -p "Monitors" -i)

        case "$menu" in
            "🖥️ All Monitors Off")
                hyprctl keyword monitor "HDMI-A-1, disable"
                sleep 0.5
                hyprctl dispatch dpms off DP-1
                ;;
            "🖥️ DP-1 Off")
                hyprctl dispatch dpms off DP-1
                ;;
            "🖥️ HDMI-A-1 Off")
                hyprctl dispatch dpms off HDMI-A-1
                ;;
            "❌ Cancel")
                ;;
        esac
        ;;
    on)
        hyprctl dispatch dpms on DP-1
        hyprctl keyword monitor "$HDMI_CONFIG"
        ;;
esac
