#!/bin/bash
set -euo pipefail

src="$HOME/flutter"
dst="$HOME/dev/flutter"

if [ ! -e "$src" ]; then
  echo "Nothing at $src"
  exit 0
fi

if [ ! -x "$src/bin/flutter" ]; then
  echo "$src is not a Flutter install." >&2
  exit 1
fi

if [ -e "$dst" ]; then
  echo "$dst already exists. Left $src in place." >&2
  exit 1
fi

mkdir -p "$HOME/dev"
mv "$src" "$dst"
echo "Moved $src to $dst"
