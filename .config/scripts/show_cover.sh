#!/bin/bash

# Get cover art URL from playerctl
cover_url=$(playerctl metadata mpris:artUrl 2>/dev/null)

if [[ -z "$cover_url" ]]; then
    notify-send "No cover art available"
    exit 1
fi

# Handle file:// URLs
if [[ "$cover_url" == file://* ]]; then
    cover_path="${cover_url#file://}"
    # Decode URL encoding
    cover_path=$(printf '%b' "${cover_path//%/\\x}")

    if [[ ! -f "$cover_path" ]]; then
        notify-send "Cover file not found"
        exit 1
    fi
else
    # It's a URL, download it
    cover_path="/tmp/album_cover_$(date +%s).jpg"

    if command -v curl &> /dev/null; then
        curl -s -L "$cover_url" -o "$cover_path" 2>/dev/null
    elif command -v wget &> /dev/null; then
        wget -q "$cover_url" -O "$cover_path" 2>/dev/null
    else
        notify-send "Need curl or wget to download cover"
        exit 1
    fi

    if [[ ! -f "$cover_path" ]] || [[ ! -s "$cover_path" ]]; then
        notify-send "Failed to download cover art"
        exit 1
    fi
fi

# Display the cover using available image viewer
if command -v feh &> /dev/null; then
    feh --geometry 500x500 --title "Album Cover" "$cover_path" 2>/dev/null &
elif command -v eog &> /dev/null; then
    eog "$cover_path" 2>/dev/null &
elif command -v display &> /dev/null; then
    display -geometry 500x500 "$cover_path" 2>/dev/null &
else
    notify-send "Install feh, eog, or imagemagick to view covers"
    exit 1
fi
