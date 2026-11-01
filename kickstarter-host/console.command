#!/bin/zsh
# Host control window. v shows or hides the VM. The VM keeps running.

here="$(cd "$(dirname "$0")" && pwd)"
urlfile="$here/.vnc.url"
printf '%s\n' "$$" > "$here/.console.pid"
trap 'rm -f "$here/.console.pid"' EXIT

print "v: show or hide"
while read -k 1 key; do
  [[ "$key" == v ]] || continue
  print
  if [[ ! -s "$urlfile" ]]; then
    print "VM has no picture yet"
    continue
  fi
  if pgrep -xq "Screen Sharing"; then
    osascript -e 'tell application "Screen Sharing" to quit' >/dev/null
    print "hidden"
  else
    open "$(cat "$urlfile")"
    print "visible"
  fi
done
