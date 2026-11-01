#!/bin/zsh
set -e
here="$(cd "$(dirname "$0")" && pwd)"
script="$here/kickstarter-host.sh"
agent="$HOME/Library/LaunchAgents/kickstarter-host.plist"
uid="$(id -u)"

domain="gui/${uid}"
launchctl bootout "$domain/kickstarter-host" 2>/dev/null || true
rm -f "$agent"

mkdir -p "$HOME/Library/LaunchAgents"
chmod +x "$script" "$here/console.command"
esc="${script//&/&amp;}"
esc="${esc//</&lt;}"
esc="${esc//>/&gt;}"
cat > "$agent" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>kickstarter-host</string>
	<key>Program</key>
	<string>${esc}</string>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<true/>
	<key>ThrottleInterval</key>
	<integer>10</integer>
	<key>LimitLoadToSessionType</key>
	<string>Aqua</string>
</dict>
</plist>
EOF
plutil -lint "$agent"
rm -f "$here/.manual-stop"
if ! launchctl bootstrap "$domain" "$agent"; then
  launchctl kickstart -k "$domain/kickstarter-host"
fi
launchctl enable "$domain/kickstarter-host"
print "kickstarter-host started"
