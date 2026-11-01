#!/bin/zsh
set -e
here="$(cd "$(dirname "$0")" && pwd)"
script="$here/kickstarter-vm.sh"
agent="$HOME/Library/LaunchAgents/kickstarter-vm.plist"
uid="$(id -u)"

mkdir -p "$HOME/Library/LaunchAgents"
chmod +x "$script" "$here/run"
esc="${script//&/&amp;}"
esc="${esc//</&lt;}"
esc="${esc//>/&gt;}"
cat > "$agent" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>kickstarter-vm</string>
	<key>Program</key>
	<string>${esc}</string>
	<key>RunAtLoad</key>
	<true/>
	<key>LimitLoadToSessionType</key>
	<string>Aqua</string>
</dict>
</plist>
EOF
plutil -lint "$agent"
# Load it for this GUI login. RunAtLoad starts kickstarter-vm.sh now and at each login.
launchctl bootstrap "gui/${uid}" "$agent"
launchctl enable "gui/${uid}/kickstarter-vm"
