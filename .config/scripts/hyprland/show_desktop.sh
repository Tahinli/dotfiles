#!/bin/bash

STATE_FILE="/tmp/hypr_show_desktop"

if [ -f "$STATE_FILE" ]; then
    source "$STATE_FILE"
    if [ -n "$MON2" ]; then
        hyprctl --batch "dispatch focusmonitor $MON2; dispatch workspace $WS_OTHER; dispatch focusmonitor $MON1; dispatch workspace $WS_FOCUSED"
    else
        hyprctl dispatch workspace "$WS_FOCUSED"
    fi
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

    # one empty dummy workspace per monitor; no swapactiveworkspaces —
    # swaps rebind workspaces to the wrong monitor and confuse waybar
    if [ -n "$MON2" ]; then
        hyprctl --batch "dispatch focusmonitor $MON2; dispatch workspace 998; dispatch focusmonitor $MON1; dispatch workspace 999"
    else
        hyprctl dispatch workspace 999
    fi
fi
