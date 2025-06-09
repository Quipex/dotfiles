#!/bin/bash

# Активирует "Automatically hide and show the menu bar" -> "Always"
set -e

if [[ "$(uname)" != "Darwin" ]]; then
  echo "❌ Not macOS — skipping menu bar autohide config"
  exit 0
fi

echo "📐 Enabling always-hide menu bar in all spaces..."

# 1. Скрывать меню-бар в обычном режиме
defaults write NSGlobalDomain _HIHideMenuBar -bool true

# 2. Скрывать меню-бар в полноэкранном режиме
defaults write com.apple.menuextra.clock ShowFullScreenHide -bool true

# 3. Применить изменения
killall SystemUIServer || true

echo "✅ Menu bar autohide enabled (Always)."
