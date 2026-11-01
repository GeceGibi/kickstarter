#!/bin/zsh
# Login agent. Reads ./paths (not in git) and opens one Terminal per existing path.

here="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$here/.windows"

# Collect non-empty, non-comment lines.
paths=()
if [[ -f "$here/paths" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    paths+=("$line")
  done < "$here/paths"
fi

# A .command file is what Terminal can launch. It hands the path to run.
for target in "${paths[@]}"; do
  if [[ ! -e "$target" ]]; then
    print -u2 -- "missing, skip: $target"
    continue
  fi
  file="$here/.windows/${target:t}.command"
  /bin/cat > "$file" <<EOF
#!/bin/zsh
exec $(printf '%q' "$here/run") $(printf '%q' "$target")
EOF
  /bin/chmod +x "$file"
  /usr/bin/open -a Terminal "$file"
done
