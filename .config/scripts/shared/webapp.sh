#!/usr/bin/env bash
# Launch a Chromium web app (github, whatsapp, deezer, mail, ...).
#
# usage: webapp.sh [--mullvad] <url> <profile-id>
#
#   --mullvad     route outside the VPN via mullvad-exclude
#   <url>         app URL, e.g. https://github.com/
#   <profile-id>  directory name under the web-app-hub profiles dir
#
# The window class is derived from the URL host as chrome-<host>__-Default,
# which is what Chromium itself would generate — it has to match, since that is
# the app-id niri and waybar see.
#
# Compositor-agnostic: usable from niri binds and Hyprland binds alike.
set -euo pipefail

BROWSER_ID="io.github.ungoogled_software.ungoogled_chromium"
PROFILES="$HOME/.var/app/$BROWSER_ID/data/web-app-hub/profiles"

MULLVAD=0
if [ "${1:-}" = "--mullvad" ]; then
    MULLVAD=1
    shift
fi

URL="${1:?usage: webapp.sh [--mullvad] <url> <profile-id>}"
PROFILE="${2:?usage: webapp.sh [--mullvad] <url> <profile-id>}"

# https://web.whatsapp.com/foo -> web.whatsapp.com
HOST="${URL#*://}"
HOST="${HOST%%/*}"
CLASS="chrome-${HOST}__-Default"

cmd=(flatpak run "$BROWSER_ID"
     --no-first-run
     --app="$URL"
     --class="$CLASS"
     --name="$CLASS"
     --user-data-dir="$PROFILES/$PROFILE")

if [ "$MULLVAD" -eq 1 ]; then
    cmd=(mullvad-exclude "${cmd[@]}")
fi

# --dry-run prints the command instead of running it, for verification.
if [ "${DRY_RUN:-0}" = "1" ]; then
    printf '%q ' "${cmd[@]}"
    printf '\n'
    exit 0
fi

exec "${cmd[@]}"
