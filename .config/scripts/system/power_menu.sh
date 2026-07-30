#!/bin/bash

menu=$(echo -e "🔴 Shutdown\n🔄 Reboot\n😴 Suspend\n🚪 Logout\n❌ Cancel" | rofi -dmenu -p "Power" -i)

case "$menu" in
    "🔴 Shutdown")
        systemctl poweroff
        ;;
    "🔄 Reboot")
        systemctl reboot
        ;;
    "😴 Suspend")
        systemctl suspend
        ;;
    "🚪 Logout")
        if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
            hyprctl dispatch exit
        elif [ -n "${NIRI_SOCKET:-}" ]; then
            niri msg action quit -s
        fi
        ;;
    "❌ Cancel")
        ;;
esac
