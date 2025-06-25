#!/usr/bin/env zsh
# ==================================
# Определение базовых цветов
# ==================================
# Используем here-string (<<<) и cut для удаления # из строки
COLOR_LIGHT_BLUE=$(cut -c 2- <<< "#8aadf4")
COLOR_DARK_BLUE=$(cut -c 2- <<< "#494d64")
COLOR_GREEN=$(cut -c 2- <<< "#a6da95")
COLOR_RED=$(cut -c 2- <<< "#ed8796")
COLOR_BLACK=$(cut -c 2- <<< "#24273a")
COLOR_WHITE=$(cut -c 2- <<< "#cad3f5")
COLOR_ORANGE=$(cut -c 2- <<< "#f5a97f")
COLOR_VIOLET=$(cut -c 2- <<< "#765999")