#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/monitors.sh"

# workspace 1 is the empty-workspace-above-first slot, so it is always free
niri msg action focus-monitor "$RIGHT_MONITOR" >/dev/null
niri msg action focus-workspace 1 >/dev/null
niri msg action focus-monitor "$LEFT_MONITOR" >/dev/null
niri msg action focus-workspace 1 >/dev/null
