#!/bin/bash

# Network Status - Shows network activity and connection status

# Get network interfaces
get_network_stats() {
    # Get RX/TX bytes for all interfaces except lo
    cat /proc/net/dev | grep -v "lo:" | grep ":" | awk '{
        rx += $2
        tx += $10
    }
    END {
        printf "%d %d\n", rx, tx
    }'
}

# Store previous values
HISTORY_FILE="/tmp/network_history.txt"
PREV_RX=0
PREV_TX=0

# Read previous values if they exist
if [ -f "$HISTORY_FILE" ]; then
    read PREV_RX PREV_TX < "$HISTORY_FILE"
fi

# Get current values
read CURR_RX CURR_TX <<< $(get_network_stats)

# Calculate difference (bytes since last check)
DELTA_RX=$((CURR_RX - PREV_RX))
DELTA_TX=$((CURR_TX - PREV_TX))

# Handle negative values (counter reset)
[ $DELTA_RX -lt 0 ] && DELTA_RX=0
[ $DELTA_TX -lt 0 ] && DELTA_TX=0

# Convert to KB/s (assuming 1 second polling interval)
RX_SPEED=$((DELTA_RX / 1024))
TX_SPEED=$((DELTA_TX / 1024))

# Save current values for next iteration
echo "$CURR_RX $CURR_TX" > "$HISTORY_FILE"

# Format speeds with units
format_speed() {
    local speed=$1
    if [ $speed -lt 1024 ]; then
        echo "${speed}KB/s"
    else
        echo "$((speed / 1024))MB/s"
    fi
}

RX_FORMATTED=$(format_speed $RX_SPEED)
TX_FORMATTED=$(format_speed $TX_SPEED)

# Check if network is connected and get active interface
ACTIVE_INTERFACE=$(ip link | grep "state UP" | grep -oP '^\d+: \K[^:]+' | head -1)
CONNECTED=$(ip link | grep -c "state UP")

# Display network status
echo "Network"
echo "======="
echo ""

if [ $CONNECTED -gt 0 ]; then
    echo "  Status: Connected"
    echo "  Interface: $ACTIVE_INTERFACE"
else
    echo "  Status: Disconnected"
fi

echo ""
echo "  ⬇ Download: $RX_FORMATTED"
echo "  ⬆ Upload:   $TX_FORMATTED"
