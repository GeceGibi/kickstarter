#!/bin/zsh
# Paths live in ./paths, one absolute path per line. That file is not in git.

list_only=0
[[ "${1:-}" == "--files" ]] && list_only=1

here="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$here/.windows"

paths=()
if [[ -f "$here/paths" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    paths+=("$line")
  done < "$here/paths"
fi

for target in "${paths[@]}"; do
  if [[ ! -e "$target" ]]; then
    [[ "$list_only" == 0 ]] && print -u2 -- "missing, skip: $target"
    continue
  fi
  file="$here/.windows/${target:t}.command"
  /bin/cat > "$file" <<EOF
#!/bin/zsh
exec $(printf '%q' "$here/run") $(printf '%q' "$target")
EOF
  /bin/chmod +x "$file"
  if [[ "$list_only" == 1 ]]; then
    print -r -- "$file"
  else
    /usr/bin/open -a Terminal "$file"
  fi
done
