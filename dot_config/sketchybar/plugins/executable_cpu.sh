#!/usr/bin/env bash
#$PLUGIN_DIR/stats/scripts/cpu.sh

sketchybar -m --set "$NAME" label="$(top -l 1 | awk '/^CPU usage/ {printf "%.0f%%", $3 + $5}')"