#!/bin/zsh
# Host control window. v shows or hides the VM. The VM keeps running.

here="$(cd "$(dirname "$0")" && pwd)"
urlfile="$here/.vnc.url"
printf '%s\n' "$$" > "$here/.console.pid"
trap 'rm -f "$here/.console.pid"' EXIT

manual_stop() {
  touch "$here/.manual-stop"
  osascript -e 'tell application "Screen Sharing" to quit' >/dev/null 2>&1 || true
  launchctl bootout "gui/$(id -u)/kickstarter-host" >/dev/null 2>&1 || true
  PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" tart stop ci-macos >/dev/null 2>&1 || true
  print
  print "stopped"
  exit 0
}
trap manual_stop INT

vm_dir="${TART_HOME:-$HOME/.tart}/vms/ci-macos"
disk="-"
disk_at=0

age() {
  local started now elapsed h m s
  started="$(awk 'NR == 1 { print $2 }' "$here/.tart.pid" 2>/dev/null)"
  [[ -n "$started" ]] || return 1
  now="$(date +%s)"
  elapsed=$((now - started))
  ((elapsed < 0)) && elapsed=0
  h=$((elapsed / 3600))
  m=$(((elapsed % 3600) / 60))
  s=$((elapsed % 60))
  if ((h > 0)); then
    printf '%dh %02dm' "$h" "$m"
  elif ((m > 0)); then
    printf '%dm %02ds' "$m" "$s"
  else
    printf '%ds' "$s"
  fi
}

usage() {
  local now
  now="$(date +%s)"
  ((now - disk_at < 60)) && return
  disk_at="$now"
  if [[ -d "$vm_dir" ]]; then
    disk="$(du -sh "$vm_dir" 2>/dev/null | awk 'NR == 1 { print $1 }')"
    [[ -n "$disk" ]] || disk="-"
  else
    disk="-"
  fi
}

show_status() {
  local up
  usage
  if up="$(age)"; then
    print -n -- "\r\e[2Kup ${up}  ${disk}"
  else
    print -n -- "\r\e[2Kdown  ${disk}"
  fi
}

print "v: show or hide"
print "k: stop"
while true; do
  show_status
  key=""
  read -k 1 -t 10 key || true
  [[ -z "$key" ]] && continue
  [[ "$key" == k ]] && manual_stop
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
