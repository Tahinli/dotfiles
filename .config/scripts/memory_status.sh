#!/bin/bash

# Memory Status - Shows memory usage with history bar chart and persistent peak tracking

HISTORY_FILE="/tmp/memory_history.txt"
PEAK_FILE="/tmp/memory_peak.txt"
PEAK_TIMESTAMP_FILE="/tmp/memory_peak_timestamp.txt"
LAST_UPDATE_FILE="/tmp/memory_status_last_update.txt"
MAX_HISTORY=20
UPDATE_INTERVAL=1000  # milliseconds

# Get current memory usage
get_memory() {
    free -b 2>/dev/null | awk 'NR==2 {
        used = $3
        total = $2
        percent = int(used * 100 / total)
        printf "%.1f %.1f %d", used/1073741824, total/1073741824, percent
    }'
}

# Read memory and add to history
current=$(get_memory)
used=$(echo $current | awk '{print $1}')
total=$(echo $current | awk '{print $2}')
percent=$(echo $current | awk '{print $3}')

# Check if we should update history (only once every 1s)
current_time_ms=$(date +%s%3N 2>/dev/null || echo $(($(date +%s) * 1000)))
last_update=$(cat "$LAST_UPDATE_FILE" 2>/dev/null || echo 0)
time_diff=$((current_time_ms - last_update))

should_update=0
if [ $time_diff -ge $UPDATE_INTERVAL ]; then
    should_update=1
    echo "$current_time_ms" > "$LAST_UPDATE_FILE"
fi

# Only update history if interval has passed
if [ $should_update -eq 1 ]; then
    # Get current timestamp
    current_time=$(date '+%H:%M:%S')

    # Append to history file
    echo "$used" >> "$HISTORY_FILE"

    # Keep only last N entries
    tail -n $MAX_HISTORY "$HISTORY_FILE" > "${HISTORY_FILE}.tmp"
    mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"

    # Initialize or read persistent peak
    if [ ! -f "$PEAK_FILE" ]; then
        echo "$used" > "$PEAK_FILE"
        echo "$current_time" > "$PEAK_TIMESTAMP_FILE"
    fi

    persistent_peak=$(cat "$PEAK_FILE" 2>/dev/null || echo "$used")
    persistent_peak_time=$(cat "$PEAK_TIMESTAMP_FILE" 2>/dev/null || echo "$current_time")

    # Update persistent peak if current usage exceeds it
    if (( $(echo "$used > $persistent_peak" | bc -l) )); then
        persistent_peak=$used
        persistent_peak_time=$current_time
        echo "$persistent_peak" > "$PEAK_FILE"
        echo "$persistent_peak_time" > "$PEAK_TIMESTAMP_FILE"
    fi
else
    # If not updating, just read the current peaks for display
    persistent_peak=$(cat "$PEAK_FILE" 2>/dev/null || echo "$used")
    persistent_peak_time=$(cat "$PEAK_TIMESTAMP_FILE" 2>/dev/null || echo "N/A")
fi

# Read history and create bar chart
mapfile -t history < "$HISTORY_FILE"

# Create bar chart
echo "Memory Status"
echo "============="
echo ""

# Draw bar chart based on history
bar=""
for val in "${history[@]}"; do
    # Calculate percentage and convert to bar
    bar_percent=$(echo "scale=0; $val * 100 / $total" | bc)
    if [ "$bar_percent" -lt 5 ]; then
        bar="${bar}▁"
    elif [ "$bar_percent" -lt 20 ]; then
        bar="${bar}▂"
    elif [ "$bar_percent" -lt 35 ]; then
        bar="${bar}▃"
    elif [ "$bar_percent" -lt 50 ]; then
        bar="${bar}▄"
    elif [ "$bar_percent" -lt 65 ]; then
        bar="${bar}▅"
    elif [ "$bar_percent" -lt 80 ]; then
        bar="${bar}▆"
    elif [ "$bar_percent" -lt 90 ]; then
        bar="${bar}▇"
    else
        bar="${bar}█"
    fi
done

echo "History: $bar"
echo ""

# Show current and peak with timestamp
persistent_peak_percent=$(echo "scale=1; $persistent_peak * 100 / $total" | bc)

echo "Current: ${used} GB / ${total} GB (${percent}%)"
echo "Peak:    ${persistent_peak} GB / ${total} GB (${persistent_peak_percent}%) (at ${persistent_peak_time})"
