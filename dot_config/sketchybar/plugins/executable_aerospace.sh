#!/usr/bin/env bash

if [[ -z "$FOCUSED_WORSPACE" ]]; then
    FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
fi

sketchybar --set "$NAME" label="$FOCUSED_WORKSPACE"