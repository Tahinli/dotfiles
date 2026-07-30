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
        # Shared by both compositors, so the exit command is picked at runtime.
        # hyprctl is a no-op under niri, which is what silently broke logout.
        #
        # Hyprland is checked FIRST on purpose: niri pushes NIRI_SOCKET into the
        # systemd --user manager environment and never unsets it on exit, so a
        # niri -> Hyprland switch that kept the same user manager alive would
        # leave a stale NIRI_SOCKET behind, and `niri msg` does not fall back to
        # socket discovery — it just errors out. That would mirror this very bug
        # onto Hyprland. The leak only goes that direction, so ordering fixes it.
        #
        # -s skips niri's "Press Enter to confirm" prompt, which has nowhere to
        # be answered when the quit comes from a rofi menu.
        if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
            hyprctl dispatch exit
        elif [ -n "${NIRI_SOCKET:-}" ]; then
            niri msg action quit -s
        fi
        ;;
    "❌ Cancel")
        ;;
esac
