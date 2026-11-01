#!/bin/zsh
# Stays up for the life of the VM. Opens one Terminal per path, and opens it
# again if that watcher has died. Run once inside base-macos; every clone starts it.

here="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$here/.windows"

alive() {
  local target="$1" line
  while IFS= read -r line; do
    case "$line" in
      *"$here/run $target") return 0 ;;
    esac
  done < <(ps -axo command=)
  return 1
}

open_one() {
  local target="$1"
  local file="$here/.windows/${target//\//_}.command"
  if [[ ! -e "$target" ]]; then
    print -u2 -- "missing, skip: $target"
    return
  fi
  if alive "$target"; then
    return
  fi
  /bin/cat > "$file" <<EOF
#!/bin/zsh
exec $(printf '%q' "$here/run") $(printf '%q' "$target")
EOF
  /bin/chmod +x "$file"
  /usr/bin/open -a Terminal "$file"
}

while true; do
  if [[ -f "$here/paths" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line#"${line%%[![:space:]]*}"}"
      line="${line%"${line##*[![:space:]]}"}"
      [[ -z "$line" || "$line" == \#* ]] && continue
      open_one "$line"
    done < "$here/paths"
  fi
  sleep 10
done
