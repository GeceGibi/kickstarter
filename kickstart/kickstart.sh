#!/bin/zsh
# One absolute path per entry. Add or remove lines here.

paths=(
  # /Users/user/script.sh
  # /Users/user/script2.sh
  # /Users/user/file.app
)

here="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$here/.windows"

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
