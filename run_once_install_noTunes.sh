#!/bin/bash

# Выполняется один раз через chezmoi на macOS
set -e

# Проверка: только macOS
if [[ "$(uname)" != "Darwin" ]]; then
  echo "❌ Not macOS — skipping noTunes setup"
  exit 0
fi

# Проверка и установка Homebrew
if ! command -v brew &>/dev/null; then
  echo "🔧 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Установка noTunes
echo "📦 Installing noTunes..."
brew install --cask notunes

# Добавление в автозагрузку (Open at Login)
echo "⚙️ Adding noTunes to Login Items..."
osascript <<EOF
tell application "System Events"
  if not (exists login item "noTunes") then
    make login item at end with properties {path:"/Applications/noTunes.app", hidden:false}
  end if
end tell
EOF

# Установка замены на YouTube Music
echo "🎶 Setting YouTube Music as replacement..."
defaults write digital.twisted.noTunes replacement "https://music.youtube.com/"

echo "✅ noTunes installed and configured."
