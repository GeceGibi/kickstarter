#!/bin/zsh
# Host control window. One line shows how long ci-macos has been up and how much
# disk the clone holds on top of base-macos, which is what deleting it frees.
# v shows or hides the VM picture. The VM keeps running. k or Control+C stops it.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

here="${0:A:h}"
name="ci-macos"
picture="vnc://192.168.64.100"
vm_dir="${TART_HOME:-$HOME/.tart}/vms/$name"

print -- "$$" > "$here/.console.pid"
trap 'rm -f "$here/.console.pid"' EXIT

stop_vm() {
  touch "$here/.manual-stop"
  osascript -e 'tell application "Screen Sharing" to quit' >/dev/null 2>&1
  print -n -- "\r\e[2Kstopping"
  tart stop "$name" >/dev/null 2>&1
  launchctl bootout "gui/$(id -u)/kickstarter-host" >/dev/null 2>&1
  tart delete "$name" >/dev/null 2>&1
  print -- "\r\e[2Kstopped"
  exit 0
}
trap stop_vm INT

# ps etime is [[dd-]hh:]mm:ss
uptime_of_vm() {
  local pid etime
  pid="$(pgrep -f "tart run .*$name\$" | head -n 1)"
  [[ -n "$pid" ]] || return 1
  etime="$(ps -o etime= -p "$pid")"
  etime="${etime// /}"
  [[ -n "$etime" ]] || return 1
  print -rn -- "${etime/-/d }"
}

clone_size() {
  local bytes
  [[ -d "$vm_dir" ]] || return 1
  bytes="$(/usr/bin/python3 "$here/private-size.py" "$vm_dir" 2>/dev/null)" || return 1
  printf '%.1fG' "$((bytes / 1073741824.0))"
}

print "v: show or hide"
print "k: stop"
size="-"
tick=0
while true; do
  if ((tick % 10 == 0)); then
    size="$(clone_size)" || size="-"
  fi
  ((tick++))
  if up="$(uptime_of_vm)"; then
    print -n -- "\r\e[2Kup ${up}  clone ${size}"
  else
    print -n -- "\r\e[2Kdown  clone ${size}"
  fi

  key=""
  read -s -k 1 -t 1 key
  case "$key" in
    k) stop_vm ;;
    v)
      if pgrep -xq "Screen Sharing"; then
        osascript -e 'tell application "Screen Sharing" to quit' >/dev/null
      elif uptime_of_vm >/dev/null; then
        open "$picture"
      fi
      ;;
  esac
done
