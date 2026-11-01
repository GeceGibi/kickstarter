#!/bin/zsh
# Registers kickstarter-host as a login service and starts it. Also clears a k stop.
set -e
here="${0:A:h}"
label="kickstarter-host"
script="$here/kickstarter-host.sh"
agent="$HOME/Library/LaunchAgents/$label.plist"
domain="gui/$(id -u)"

launchctl bootout "$domain/$label" 2>/dev/null || true
# bootout returns before the old service is gone; bootstrap fails with error 5 until then.
while launchctl print "$domain/$label" >/dev/null 2>&1; do sleep 0.5; done
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
	<string>$label</string>
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
launchctl enable "$domain/$label"
launchctl bootstrap "$domain" "$agent"
print "$label started"
