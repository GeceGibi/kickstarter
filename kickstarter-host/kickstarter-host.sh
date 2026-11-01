#!/bin/bash
# Host login service. Runs a throwaway clone of base-macos. Never starts base-macos.
# The VM has no window of its own. Screen Sharing opens vnc://192.168.64.100.
# v in the control terminal hides or shows it again.

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

here="$(cd "$(dirname "$0")" && pwd)"
base="base-macos"
name="ci-macos"
picture="vnc://192.168.64.100"
urlfile="$here/.vnc.url"
shown="$here/.vnc.shown"

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
  osascript -e 'tell application "Screen Sharing" to quit' >/dev/null 2>&1 || true
}

tart_pid() {
  awk 'NR == 1 { print $1 }' "$here/.tart.pid" 2>/dev/null
}

tart_up() {
  local pid
  pid="$(tart_pid)"
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" 2>/dev/null
}

tart_young() {
  local started now
  started="$(awk 'NR == 1 { print $2 }' "$here/.tart.pid" 2>/dev/null)"
  [[ -n "$started" ]] || return 1
  now="$(date +%s)"
  (( now - started < 30 ))
}

show_once() {
  [[ -f "$shown" ]] && return
  nc -z -G 1 192.168.64.100 5900 2>/dev/null || return
  touch "$shown"
  open "$picture"
}

start_vm() {
  printf '%s\n' "$picture" > "$urlfile"
  rm -f "$shown"
  tart run --no-graphics "$name" &
  local pid=$!
  printf '%s %s\n' "$pid" "$(date +%s)" > "$here/.tart.pid"
  wait "$pid"
  rm -f "$here/.tart.pid"
}

while true; do
  open_console
  if running; then
    [[ -s "$urlfile" ]] || printf '%s\n' "$picture" > "$urlfile"
    show_once
    sleep 10
    continue
  fi
  if tart_up && tart_young; then
    sleep 10
    continue
  fi
  if tart_up; then
    kill "$(tart_pid)" 2>/dev/null || true
    sleep 1
  fi
  rm -f "$here/.tart.pid"
  hide
  tart stop "$name" >/dev/null 2>&1 || true
  tart delete "$name" >/dev/null 2>&1 || true
  if tart clone "$base" "$name"; then
    rm -f "${TART_HOME:-$HOME/.tart}/vms/$name/state.vzvmsave"
    start_vm &
  else
    echo "clone failed: $base -> $name" >&2
  fi
  sleep 10
done
