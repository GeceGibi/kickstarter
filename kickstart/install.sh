#!/bin/zsh
set -e
here="$(cd "$(dirname "$0")" && pwd)"
script="$here/kickstart.sh"
agent="$HOME/Library/LaunchAgents/kickstart.plist"
uid="$(id -u)"

# Stop Terminal jobs this kickstart folder already started.
ps -axo pid=,command= | while read -r pid cmd; do
  case "$cmd" in
    *"$here/run"*|*"$here/.windows/"*) ;;
    *) continue ;;
  esac
  pgid="$(ps -o pgid= -p "$pid" 2>/dev/null | tr -d ' ')"
  if [[ "$pgid" == <-> && "$pgid" != 0 ]]; then
    kill -TERM -- "-$pgid" 2>/dev/null || true
  else
    kill -TERM "$pid" 2>/dev/null || true
  fi
done

# Remove the old agent, then write a new one with this machine's absolute path.
launchctl bootout "gui/${uid}/kickstart" 2>/dev/null || true
rm -f "$agent"
rm -rf "$here/.windows"

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
	<string>kickstart</string>
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
# Load it for this GUI login. RunAtLoad starts kickstart.sh now and at each login.
launchctl bootstrap "gui/${uid}" "$agent"
launchctl enable "gui/${uid}/kickstart"
