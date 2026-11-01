#!/bin/zsh
set -e
here="$(cd "$(dirname "$0")" && pwd)"
agent="$HOME/Library/LaunchAgents/kickstart.plist"
uid="$(id -u)"
mkdir -p "$HOME/Library/LaunchAgents"
chmod +x "$here/kickstart.sh" "$here/run"
launchctl bootout "gui/${uid}/kickstart" 2>/dev/null || true
rm -f "$agent"

files=()
while IFS= read -r line; do
  [[ -n "$line" ]] && files+=("$line")
done < <("$here/kickstart.sh" --files)

if (( ${#files} == 0 )); then
  exit 0
fi

{
  print -r -- '<?xml version="1.0" encoding="UTF-8"?>'
  print -r -- '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
  print -r -- '<plist version="1.0"><dict>'
  print -r -- '<key>Label</key><string>kickstart</string>'
  print -r -- '<key>ProgramArguments</key><array>'
  print -r -- '<string>/usr/bin/open</string><string>-a</string><string>Terminal</string>'
  for file in "${files[@]}"; do
    esc="${file//&/&amp;}"
    esc="${esc//</&lt;}"
    esc="${esc//>/&gt;}"
    print -r -- "<string>${esc}</string>"
  done
  print -r -- '</array>'
  print -r -- '<key>RunAtLoad</key><true/>'
  print -r -- '<key>LimitLoadToSessionType</key><string>Aqua</string>'
  print -r -- '</dict></plist>'
} > "$agent"

plutil -lint "$agent"
launchctl bootstrap "gui/${uid}" "$agent"
launchctl enable "gui/${uid}/kickstart"
