#!/bin/bash
# Host login service. Runs a throwaway clone of base-macos. Never starts base-macos.
# The VM has no window of its own. Screen Sharing opens when the picture is ready.
# v in the control terminal hides or shows it again.

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

here="$(cd "$(dirname "$0")" && pwd)"
base="base-macos"
name="ci-macos"
urlfile="$here/.vnc.url"

running() {
  tart get "$name" --format json 2>/dev/null | grep -q '"Running" *: *true'
}

console_up() {
  [[ -f "$here/.console.pid" ]] || return 1
  kill -0 "$(cat "$here/.console.pid")" 2>/dev/null
}

open_console() {
  if console_up; then
    return
  fi
  /usr/bin/open -a Terminal "$here/console.command"
}

hide() {
  rm -f "$urlfile"
  osascript -e 'tell application "Screen Sharing" to quit' >/dev/null 2>&1 || true
}

tart_up() {
  [[ -f "$here/.tart.pid" ]] || return 1
  kill -0 "$(cat "$here/.tart.pid")" 2>/dev/null
}

start_vm() {
  local log="$here/.tart.log" line url
  rm -f "$log"
  mkfifo "$log"
  script -qF "$log" tart run --no-graphics --vnc "$name" &
  printf '%s\n' "$!" > "$here/.tart.pid"
  while IFS= read -r line; do
    line="${line%$'\r'}"
    printf '%s\n' "$line"
    case "$line" in
      *"VNC server is running at "*)
        url="${line##*VNC server is running at }"
        url="${url%$'\r'}"
        printf '%s\n' "$url" > "$urlfile"
        open "$url"
        ;;
    esac
  done < "$log"
  rm -f "$log" "$here/.tart.pid"
}

open_console

while true; do
  if ! running && ! tart_up; then
    hide
    tart stop "$name" >/dev/null 2>&1 || true
    tart delete "$name" >/dev/null 2>&1 || true
    if tart clone "$base" "$name"; then
      # base-macos may contain a suspended session. Drop it so the clone boots clean.
      rm -f "${TART_HOME:-$HOME/.tart}/vms/$name/state.vzvmsave"
      start_vm &
    else
      echo "clone failed: $base -> $name" >&2
    fi
  fi
  sleep 10
done
