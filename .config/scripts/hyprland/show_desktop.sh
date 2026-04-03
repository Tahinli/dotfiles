#!/bin/bash

STATE_FILE="/tmp/hypr_show_desktop"

if [ -f "$STATE_FILE" ]; then
    source "$STATE_FILE"
    hyprctl dispatch workspace "$WS_OTHER"
    hyprctl dispatch swapactiveworkspaces "$MON1" "$MON2"
    hyprctl dispatch workspace "$WS_FOCUSED"
    rm "$STATE_FILE"
else
    mon_json=$(hyprctl monitors -j)
    MON1=$(echo "$mon_json" | jq -r '.[] | select(.focused==true) | .name')
    WS_FOCUSED=$(echo "$mon_json" | jq -r '.[] | select(.focused==true) | .activeWorkspace.id')
    MON2=$(echo "$mon_json" | jq -r '.[] | select(.focused==false) | .name')
    WS_OTHER=$(echo "$mon_json" | jq -r '.[] | select(.focused==false) | .activeWorkspace.id')

    cat > "$STATE_FILE" << EOF
MON1=$MON1
MON2=$MON2
WS_FOCUSED=$WS_FOCUSED
WS_OTHER=$WS_OTHER
EOF

    hyprctl dispatch workspace 998
    hyprctl dispatch swapactiveworkspaces "$MON1" "$MON2"
    hyprctl dispatch workspace 999
fi
