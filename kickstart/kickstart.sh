#!/bin/zsh
# One absolute path per entry. Add or remove lines here.

paths=(
  # /Users/user/script.sh
  # /Users/user/executable
)

list_only=0
[[ "${1:-}" == "--files" ]] && list_only=1

here="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$here/.windows"

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
