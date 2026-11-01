#!/bin/bash
set -euo pipefail

# Apple Silicon only.
if [ "$(uname -m)" != "arm64" ]; then
  echo "This script is for Apple Silicon (arm64)." >&2
  exit 1
fi

root="$(cd "$(dirname "$0")" && pwd)"
dev="$HOME/dev"
flutter_home="$dev/flutter"

# Xcode or the Command Line Tools must exist before Homebrew and git.
if ! xcode-select -p >/dev/null 2>&1; then
  if [ -d /Applications/Xcode.app ]; then
    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  else
    xcode-select --install || true
    echo "Finish the Command Line Tools window, then run setup.sh again." >&2
    exit 1
  fi
fi

# Use Homebrew if it is already installed, otherwise install it.
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
else
  echo "==> Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install a formula or cask only when it is missing.
brew_formula() {
  if brew list --formula "$1" >/dev/null 2>&1; then
    return 0
  fi
  echo "==> brew install $1"
  brew install "$1"
}

brew_cask() {
  if brew list --cask "$1" >/dev/null 2>&1; then
    return 0
  fi
  echo "==> brew install --cask $1"
  brew install --cask "$1"
}

# Java 17, Android command-line tools, CocoaPods, Fastlane.
brew_cask temurin@17
brew_cask android-commandlinetools
brew_formula cocoapods
brew_formula fastlane

# Flutter lives at ~/dev/flutter. Clone stable only when the binary is missing.
mkdir -p "$dev"
if [ ! -x "$flutter_home/bin/flutter" ]; then
  echo "==> Flutter"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$flutter_home"
fi

# Shell env for Flutter, Java, sdkmanager, and adb. New terminals read this from ~/.zshrc.
cat > "$dev/env.sh" <<'EOF'
eval "$(/opt/homebrew/bin/brew shellenv)"
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
export ANDROID_HOME="$(brew --prefix)/share/android-commandlinetools"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$HOME/dev/flutter/bin:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
EOF

# Replace the runner-setup block in ~/.zshrc and drop an old ~/flutter/bin path.
zshrc="$HOME/.zshrc"
touch "$zshrc"
tmp="$(mktemp)"
awk '
  /^# >>> runner-setup >>>$/ { skip=1; next }
  /^# <<< runner-setup <<</ { skip=0; next }
  skip { next }
  /java_home -v 17/ { next }
  /ANDROID_HOME=.*android-commandlinetools/ { next }
  /cmdline-tools\/latest\/bin/ { next }
  /flutter\/bin/ && !/dev\/flutter\/bin/ { next }
  { print }
' "$zshrc" > "$tmp"
cat "$tmp" > "$zshrc"
rm -f "$tmp"
cat >> "$zshrc" <<'EOF'
# >>> runner-setup >>>
[ -f "$HOME/dev/env.sh" ] && . "$HOME/dev/env.sh"
# <<< runner-setup <<<
EOF

# Stop if the PATH files were not written.
if ! grep -F -q '$HOME/dev/env.sh' "$zshrc" || ! grep -F -q '$HOME/dev/flutter/bin' "$dev/env.sh"; then
  echo "Failed to write Flutter to PATH in ~/.zshrc" >&2
  exit 1
fi
echo "PATH is in ~/.zshrc. Open a new terminal, or run: source ~/.zshrc"
# This process needs the same PATH for sdkmanager and flutter.
. "$dev/env.sh"

# Read the Android platform and NDK versions Flutter expects.
ext="$flutter_home/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt"
compile="$(sed -n 's/.*compileSdkVersion: Int = \([0-9][0-9]*\).*/\1/p' "$ext")"
ndk="$(sed -n 's/.*ndkVersion: String = "\([^"]*\)".*/\1/p' "$ext")"
compile="${compile%%$'\n'*}"
ndk="${ndk%%$'\n'*}"
if [ -z "$compile" ] || [ -z "$ndk" ]; then
  echo "Could not read the Flutter Android version: $ext" >&2
  exit 1
fi

# Accept Android licenses, then install any missing SDK packages.
yes | sdkmanager --licenses >/dev/null || true

sdk_install() {
  if sdkmanager --list_installed 2>/dev/null | grep -F "$1" >/dev/null; then
    return 0
  fi
  echo "==> sdkmanager $1"
  sdkmanager "$1"
}

sdk_install "platform-tools"
sdk_install "platforms;android-${compile}"
sdk_install "build-tools;${compile}.0.0"
sdk_install "ndk;${ndk}"

# Point Flutter at the SDK and download engine artifacts.
flutter config --android-sdk "$ANDROID_HOME" --no-analytics
flutter precache --android

# iOS builds need Xcode.app. Android setup still finishes without it.
if [ -d /Applications/Xcode.app ]; then
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  sudo xcodebuild -license accept
  flutter precache --ios
else
  echo "Xcode.app is missing. Android is ready. Install Xcode, then run setup.sh again." >&2
fi

# Register kickstart.sh as the login agent.
echo "==> LaunchAgent"
"$root/kickstart/install.sh"
