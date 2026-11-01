#!/bin/zsh
set -e
here="$(cd "$(dirname "$0")" && pwd)"
agent="$HOME/Library/LaunchAgents/kickstart.plist"
mkdir -p "$HOME/Library/LaunchAgents"
chmod +x "$here/kickstart.sh" "$here/run"
ln -sfn "$here/kickstart.plist" "$agent"
plutil -lint "$agent"
uid="$(id -u)"
launchctl bootout "gui/${uid}/kickstart" 2>/dev/null || true
launchctl bootstrap "gui/${uid}" "$agent"
launchctl enable "gui/${uid}/kickstart"
