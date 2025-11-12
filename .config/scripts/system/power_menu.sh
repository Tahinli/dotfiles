#!/bin/bash

# Power Management Menu
# Provides quick access to suspend, shutdown, reboot, and logout options

# Create menu options
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
        hyprctl dispatch exit
        ;;
    "❌ Cancel")
        ;;
esac
