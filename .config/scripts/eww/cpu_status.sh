#!/bin/bash

# CPU Status - Shows per-core usage, overall usage history, and temperature history with persistent peak tracking

HISTORY_FILE="/tmp/cpu_history.txt"
TEMP_HISTORY_FILE="/tmp/cpu_temp_history.txt"
CPU_PEAK_FILE="/tmp/cpu_peak.txt"
CPU_PEAK_TIMESTAMP_FILE="/tmp/cpu_peak_timestamp.txt"
TEMP_PEAK_FILE="/tmp/cpu_temp_peak.txt"
TEMP_PEAK_TIMESTAMP_FILE="/tmp/cpu_temp_peak_timestamp.txt"
LAST_UPDATE_FILE="/tmp/cpu_status_last_update.txt"
MAX_HISTORY=20
UPDATE_INTERVAL=1000  # milliseconds

cores=$(nproc)

# Function to read CPU stats from /proc/stat
read_cpu_stats() {
    grep "^cpu" /proc/stat | grep -v "^cpu " | head -n $(nproc)
}

# Function to calculate usage from stats
calculate_usage() {
    local prev_line="$1"
    local curr_line="$2"

    read -r prev_cpu prev_user prev_nice prev_system prev_idle prev_iowait prev_irq prev_softirq <<< "$prev_line"
    read -r curr_cpu curr_user curr_nice curr_system curr_idle curr_iowait curr_irq curr_softirq <<< "$curr_line"

    local user_diff=$((curr_user - prev_user))
    local nice_diff=$((curr_nice - prev_nice))
    local system_diff=$((curr_system - prev_system))
    local idle_diff=$((curr_idle - prev_idle))

    local total_diff=$((user_diff + nice_diff + system_diff + idle_diff))
    local used_diff=$((user_diff + nice_diff + system_diff))

    if [ $total_diff -gt 0 ]; then
        echo $((used_diff * 100 / total_diff))
    else
        echo 0
    fi
}

# Check if we should update history (only once every 1s)
current_time_ms=$(date +%s%3N 2>/dev/null || echo $(($(date +%s) * 1000)))
last_update=$(cat "$LAST_UPDATE_FILE" 2>/dev/null || echo 0)
time_diff=$((current_time_ms - last_update))

should_update=0
if [ $time_diff -ge $UPDATE_INTERVAL ]; then
    should_update=1
    echo "$current_time_ms" > "$LAST_UPDATE_FILE"
fi

# Sample CPU stats twice with delay
mapfile -t stats_before < <(read_cpu_stats)
sleep 0.1
mapfile -t stats_after < <(read_cpu_stats)

# Get overall CPU usage
cpu_overall=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
cpu_overall_int=${cpu_overall%.*}

# Only update history if interval has passed
if [ $should_update -eq 1 ]; then
    # Get current timestamp
    current_time=$(date '+%H:%M:%S')

    # Add to CPU usage history
    echo "$cpu_overall_int" >> "$HISTORY_FILE"
    tail -n $MAX_HISTORY "$HISTORY_FILE" > "${HISTORY_FILE}.tmp"
    mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"

    # Get CPU temperature from hwmon2 (Tctl)
    cpu_temp=0
    if [ -f "/sys/class/hwmon/hwmon2/temp1_input" ]; then
        temp_raw=$(cat /sys/class/hwmon/hwmon2/temp1_input 2>/dev/null)
        cpu_temp=$((temp_raw / 1000))
    fi

    # Add to temperature history
    echo "$cpu_temp" >> "$TEMP_HISTORY_FILE"
    tail -n $MAX_HISTORY "$TEMP_HISTORY_FILE" > "${TEMP_HISTORY_FILE}.tmp"
    mv "${TEMP_HISTORY_FILE}.tmp" "$TEMP_HISTORY_FILE"

    # Initialize or read persistent CPU peak
    if [ ! -f "$CPU_PEAK_FILE" ]; then
        echo "$cpu_overall_int" > "$CPU_PEAK_FILE"
        echo "$current_time" > "$CPU_PEAK_TIMESTAMP_FILE"
    fi

    persistent_cpu_peak=$(cat "$CPU_PEAK_FILE" 2>/dev/null || echo "$cpu_overall_int")
    persistent_cpu_peak_time=$(cat "$CPU_PEAK_TIMESTAMP_FILE" 2>/dev/null || echo "$current_time")

    # Update persistent CPU peak if current usage exceeds it
    if [ "$cpu_overall_int" -gt "$persistent_cpu_peak" ]; then
        persistent_cpu_peak=$cpu_overall_int
        persistent_cpu_peak_time=$current_time
        echo "$persistent_cpu_peak" > "$CPU_PEAK_FILE"
        echo "$persistent_cpu_peak_time" > "$CPU_PEAK_TIMESTAMP_FILE"
    fi

    # Initialize or read persistent temperature peak
    if [ ! -f "$TEMP_PEAK_FILE" ]; then
        echo "$cpu_temp" > "$TEMP_PEAK_FILE"
        echo "$current_time" > "$TEMP_PEAK_TIMESTAMP_FILE"
    fi

    persistent_temp_peak=$(cat "$TEMP_PEAK_FILE" 2>/dev/null || echo "$cpu_temp")
    persistent_temp_peak_time=$(cat "$TEMP_PEAK_TIMESTAMP_FILE" 2>/dev/null || echo "$current_time")

    # Update persistent temperature peak if current temp exceeds it
    if [ "$cpu_temp" -gt "$persistent_temp_peak" ]; then
        persistent_temp_peak=$cpu_temp
        persistent_temp_peak_time=$current_time
        echo "$persistent_temp_peak" > "$TEMP_PEAK_FILE"
        echo "$persistent_temp_peak_time" > "$TEMP_PEAK_TIMESTAMP_FILE"
    fi
else
    # If not updating, just read the current peaks for display
    cpu_temp=0
    if [ -f "/sys/class/hwmon/hwmon2/temp1_input" ]; then
        temp_raw=$(cat /sys/class/hwmon/hwmon2/temp1_input 2>/dev/null)
        cpu_temp=$((temp_raw / 1000))
    fi

    persistent_cpu_peak=$(cat "$CPU_PEAK_FILE" 2>/dev/null || echo "$cpu_overall_int")
    persistent_cpu_peak_time=$(cat "$CPU_PEAK_TIMESTAMP_FILE" 2>/dev/null || echo "N/A")
    persistent_temp_peak=$(cat "$TEMP_PEAK_FILE" 2>/dev/null || echo "$cpu_temp")
    persistent_temp_peak_time=$(cat "$TEMP_PEAK_TIMESTAMP_FILE" 2>/dev/null || echo "N/A")
fi

# Read CPU usage history
mapfile -t cpu_history < "$HISTORY_FILE"

# Read temperature history
mapfile -t temp_history < "$TEMP_HISTORY_FILE"

# Display header
echo "CPU Status"
echo "=========="
echo ""

# Get current CPU governor
current_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "N/A")
echo "Governor: $current_governor"
echo ""

# Draw CPU usage history bar chart
cpu_bar=""
for val in "${cpu_history[@]}"; do
    if [ "$val" -lt 5 ]; then
        cpu_bar="${cpu_bar}▁"
    elif [ "$val" -lt 20 ]; then
        cpu_bar="${cpu_bar}▂"
    elif [ "$val" -lt 35 ]; then
        cpu_bar="${cpu_bar}▃"
    elif [ "$val" -lt 50 ]; then
        cpu_bar="${cpu_bar}▄"
    elif [ "$val" -lt 65 ]; then
        cpu_bar="${cpu_bar}▅"
    elif [ "$val" -lt 80 ]; then
        cpu_bar="${cpu_bar}▆"
    elif [ "$val" -lt 90 ]; then
        cpu_bar="${cpu_bar}▇"
    else
        cpu_bar="${cpu_bar}█"
    fi
done

echo "CPU Usage:"
echo "  History: $cpu_bar"
echo "  Current: ${cpu_overall_int}% | Peak: ${persistent_cpu_peak}% (at ${persistent_cpu_peak_time})"
echo ""

# Draw temperature history bar chart (scale 30-80°C)
temp_bar=""
for val in "${temp_history[@]}"; do
    # Map temperature to 30-80°C range to bar chart
    if [ "$val" -lt 35 ]; then
        temp_bar="${temp_bar}▁"
    elif [ "$val" -lt 40 ]; then
        temp_bar="${temp_bar}▂"
    elif [ "$val" -lt 45 ]; then
        temp_bar="${temp_bar}▃"
    elif [ "$val" -lt 50 ]; then
        temp_bar="${temp_bar}▄"
    elif [ "$val" -lt 55 ]; then
        temp_bar="${temp_bar}▅"
    elif [ "$val" -lt 60 ]; then
        temp_bar="${temp_bar}▆"
    elif [ "$val" -lt 70 ]; then
        temp_bar="${temp_bar}▇"
    else
        temp_bar="${temp_bar}█"
    fi
done

echo "Temperature:"
echo "  History: $temp_bar"
echo "  Current: ${cpu_temp}°C | Peak: ${persistent_temp_peak}°C (at ${persistent_temp_peak_time})"
echo ""

# Display per-core usage
echo "Per-Core Usage:"
for i in "${!stats_before[@]}"; do
    usage=$(calculate_usage "${stats_before[$i]}" "${stats_after[$i]}")
    printf "  Core %2d: %3d%%\n" "$i" "$usage"
done
