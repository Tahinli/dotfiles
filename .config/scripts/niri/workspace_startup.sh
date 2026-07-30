#!/usr/bin/env bash
# Put every output on a plain (unnamed) workspace at login.
#
# The app workspaces are declared in config.kdl, so niri creates them all on one
# output at startup and that output comes up showing "code" — the first declared
# one — instead of an empty workspace. Nothing else moves them until their
# Alt+<letter> bind runs, so the fix is a one-shot nudge: focus the first plain
# workspace on each output, then hand focus back to the output that had it
# (the one with `focus-at-startup`).
#
# focus-workspace takes an index into the FOCUSED output's list, hence the
# focus-monitor before each one — same reason workspace_nav.sh scopes by output.
set -euo pipefail

ws=$(niri msg -j workspaces)
home=$(jq -r '.[] | select(.is_focused == true) | .output' <<<"$ws")

while read -r out; do
    idx=$(jq -r --arg o "$out" '
        [ .[] | select(.output == $o and .name == null) ] | sort_by(.idx) | .[0].idx // empty
    ' <<<"$ws")
    [ -n "$idx" ] || continue
    niri msg action focus-monitor "$out" >/dev/null
    niri msg action focus-workspace "$idx" >/dev/null
done < <(jq -r '[ .[].output ] | unique | .[]' <<<"$ws")

if [ -n "$home" ]; then
    niri msg action focus-monitor "$home" >/dev/null
fi
