#!/bin/bash
# Host login service. Runs a throwaway clone of base-macos and never starts base-macos.
# A ci-macos that is already running is left alone. The clone is deleted only after it stops.
# The VM has no window. v in the control terminal opens vnc://192.168.64.100.

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

here="$(cd "$(dirname "$0")" && pwd)"
base="base-macos"
name="ci-macos"
stopfile="$here/.manual-stop"
pid=""

vm_up() {
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null && return 0
  tart get "$name" --format json 2>/dev/null | grep -q '"Running" *: *true'
}

open_console() {
  if [[ -f "$here/.console.pid" ]] && kill -0 "$(cat "$here/.console.pid")" 2>/dev/null; then
    return
  fi
  open -a Terminal "$here/console.command"
}

hide() {
  osascript -e 'tell application "Screen Sharing" to quit' >/dev/null 2>&1 || true
}

# k in the control terminal leaves a stop file. Stay stopped until install.sh is run again.
stay_stopped() {
  hide
  tart stop "$name" >/dev/null 2>&1 || true
  tart delete "$name" >/dev/null 2>&1 || true
  launchctl bootout "gui/$(id -u)/kickstarter-host" >/dev/null 2>&1
  exit 0
}

while true; do
  [[ -f "$stopfile" ]] && stay_stopped
  open_console
  if vm_up; then
    sleep 10
    continue
  fi
  pid=""
  hide
  tart delete "$name" >/dev/null 2>&1 || true
  if tart clone "$base" "$name"; then
    tart run --no-graphics "$name" &
    pid=$!
  else
    echo "clone failed: $base -> $name" >&2
  fi
  sleep 10
done
