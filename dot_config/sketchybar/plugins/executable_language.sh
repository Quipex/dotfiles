#!/usr/bin/env zsh

# Получаем текущий активный SourceID (идентификатор раскладки)
current_source=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources | egrep -w 'KeyboardLayout Name' | sed -E 's/.+ = "?([^"]+)"?;/\1/')

# Сопоставляем SourceID с удобным названием языка
case "$current_source" in
    "Polish Pro")
        lang="PL"
        ;;
    "RussianWin")
        lang="RU"
        ;;
    *)
        lang="$current_source" # Для неизвестных или других языков
        ;;
esac

sketchybar --set $NAME label="$lang"
