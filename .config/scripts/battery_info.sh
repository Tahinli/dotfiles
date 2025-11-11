#!/bin/bash

# Battery Information Script
# Displays detailed battery status and health information from real hardware

BATTERY_DIR=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)

if [ -z "$BATTERY_DIR" ]; then
    echo "Battery Details"
    echo "==============="
    echo ""
    echo "No battery detected"
    exit 1
fi

# Read battery information
CAPACITY=$(cat "$BATTERY_DIR/capacity" 2>/dev/null || echo "N/A")
STATUS=$(cat "$BATTERY_DIR/status" 2>/dev/null || echo "N/A")
HEALTH=$(cat "$BATTERY_DIR/health" 2>/dev/null || echo "N/A")
TECHNOLOGY=$(cat "$BATTERY_DIR/technology" 2>/dev/null || echo "N/A")
CYCLE_COUNT=$(cat "$BATTERY_DIR/cycle_count" 2>/dev/null || echo "N/A")

CURRENT=$(cat "$BATTERY_DIR/current_now" 2>/dev/null || echo "0")
VOLTAGE=$(cat "$BATTERY_DIR/voltage_now" 2>/dev/null || echo "0")
POWER=$(cat "$BATTERY_DIR/power_now" 2>/dev/null || echo "0")
ENERGY_FULL=$(cat "$BATTERY_DIR/energy_full" 2>/dev/null || echo "0")
ENERGY_NOW=$(cat "$BATTERY_DIR/energy_now" 2>/dev/null || echo "0")
TEMP=$(cat "$BATTERY_DIR/temp" 2>/dev/null || echo "0")

# Format output
echo "Battery Details"
echo "==============="
echo ""
echo "Capacity: ${CAPACITY}%"
echo "Status: $STATUS"
echo "Health: $HEALTH"
echo "Technology: $TECHNOLOGY"
echo ""

# Convert and display electrical info
if [ "$VOLTAGE" != "0" ]; then
    VOLTAGE_V=$(echo "scale=2; $VOLTAGE / 1000000" | bc 2>/dev/null)
    echo "Voltage: ${VOLTAGE_V}V"
fi

if [ "$CURRENT" != "0" ]; then
    CURRENT_MA=$((CURRENT / 1000))
    echo "Current: ${CURRENT_MA}mA"
fi

if [ "$POWER" != "0" ]; then
    POWER_W=$(echo "scale=2; $POWER / 1000000" | bc 2>/dev/null)
    echo "Power: ${POWER_W}W"
fi

if [ "$TEMP" != "0" ]; then
    TEMP_C=$(echo "scale=1; $TEMP / 10" | bc 2>/dev/null)
    echo "Temperature: ${TEMP_C}°C"
fi

echo ""
echo "Cycle Count: $CYCLE_COUNT"

# Display energy info
if [ "$ENERGY_FULL" != "0" ]; then
    ENERGY_FULL_WH=$(echo "scale=1; $ENERGY_FULL / 1000000" | bc 2>/dev/null)
    ENERGY_NOW_WH=$(echo "scale=1; $ENERGY_NOW / 1000000" | bc 2>/dev/null)
    echo "Energy Full: ${ENERGY_FULL_WH}Wh"
    echo "Energy Now: ${ENERGY_NOW_WH}Wh"
fi

# Estimate time to full/empty
if [ "$POWER" != "0" ] && [ "$POWER" != "0" ]; then
    if [ "$STATUS" = "Discharging" ]; then
        TIME_REMAINING=$((ENERGY_NOW / (POWER / 1000000)))
        HOURS=$((TIME_REMAINING / 3600))
        MINUTES=$(((TIME_REMAINING % 3600) / 60))
        echo ""
        echo "Time to Empty: ${HOURS}h ${MINUTES}m"
    elif [ "$STATUS" = "Charging" ]; then
        TIME_REMAINING=$(( (ENERGY_FULL - ENERGY_NOW) / (POWER / 1000000)))
        HOURS=$((TIME_REMAINING / 3600))
        MINUTES=$(((TIME_REMAINING % 3600) / 60))
        echo ""
        echo "Time to Full: ${HOURS}h ${MINUTES}m"
    fi
fi
