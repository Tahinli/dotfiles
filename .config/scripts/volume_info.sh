#!/bin/bash
# Get volume info with song details for tooltip

# Get current volume
volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{printf "%.0f", $2*100}' || echo "0")

# Get mute status
mute_status=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q MUTED && echo "true" || echo "false")

# Get sink info
sink_name=$(pactl info 2>/dev/null | grep "Default Sink:" | awk -F': ' '{print $2}')
sink_desc=$(pactl list sinks 2>/dev/null | grep -A1 "Name: $sink_name" | grep "Description:" | awk -F': ' '{print $2}')

# Format volume bar (10 segments)
bar_segments=$((volume / 10))
filled=$(printf '█%.0s' $(seq 1 $bar_segments))
empty=$(printf '░%.0s' $(seq 1 $((10 - bar_segments))))
volume_bar="${filled}${empty}"

# Format mute status
if [[ "$mute_status" == "true" ]]; then
    mute_text="Muted"
else
    mute_text="Unmuted"
fi

# Output tooltip
echo "Volume"
echo "======"
echo ""
echo "  Status: ${mute_text}"

if [[ -n "$sink_desc" ]]; then
    echo "  Device: ${sink_desc}"
fi

echo ""
echo "  ${volume_bar} ${volume}%"
