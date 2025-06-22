#!/usr/bin/env bash

if [[ -z "$FOCUSED_WORSPACE" ]]; then
    FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
fi

update_space() {
    FILTER='.[0]."monitor-name"'
    MONITOR_NAME=$(aerospace list-monitors --focused --json | jq -r "$FILTER")

    case $MONITOR_NAME in
    "Built-in Retina Display")
        ICON=
        ICON_PADDING_LEFT=7
        ICON_PADDING_RIGHT=7
        LOCALIZED_NAME='Native'
        ;;
    "Q27G3XMN")
        ICON=󰍹
        ICON_PADDING_LEFT=7
        ICON_PADDING_RIGHT=7
        LOCALIZED_NAME='AOC'
        ;;
    *)
        ICON=󰍹
        ICON_PADDING_LEFT=7
        ICON_PADDING_RIGHT=7
        LOCALIZED_NAME=$MONITOR_NAME
    esac

    sketchybar --set $NAME \
        icon=$ICON \
        icon.padding_left=$ICON_PADDING_LEFT \
        icon.padding_right=$ICON_PADDING_RIGHT
}

update_space

sketchybar --set $NAME.name label="$FOCUSED_WORKSPACE"