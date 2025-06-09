#!/bin/bash

# Включает перетаскивание окон по жесту (macOS only)
set -e

if [[ "$(uname)" != "Darwin" ]]; then
  echo "❌ Not macOS — skipping NSWindowShouldDragOnGesture tweak"
  exit 0
fi

echo "🖱️ Enabling NSWindowShouldDragOnGesture..."
defaults write -g NSWindowShouldDragOnGesture -bool true
echo "✅ NSWindowShouldDragOnGesture enabled."
