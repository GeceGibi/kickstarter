#!/bin/bash
set -euo pipefail

src="$HOME/flutter"
dst="$HOME/dev/flutter"
zshrc="$HOME/.zshrc"

if [ -x "$src/bin/flutter" ]; then
  if [ -e "$dst" ]; then
    echo "$dst already exists. Left $src in place." >&2
    exit 1
  fi
  mkdir -p "$HOME/dev"
  mv "$src" "$dst"
  echo "Moved $src to $dst"
fi

if [ ! -x "$dst/bin/flutter" ]; then
  echo "No Flutter at $dst" >&2
  exit 1
fi

touch "$zshrc"
if grep -F -q "$src/bin" "$zshrc"; then
  sed -i '' "s|$src/bin|$dst/bin|g" "$zshrc"
fi
if grep -F -q '$HOME/flutter/bin' "$zshrc"; then
  sed -i '' 's|\$HOME/flutter/bin|$HOME/dev/flutter/bin|g' "$zshrc"
fi
if ! grep -F -q "$dst/bin" "$zshrc" && ! grep -F -q '$HOME/dev/flutter/bin' "$zshrc"; then
  printf '\nexport PATH="$HOME/dev/flutter/bin:$PATH"\n' >> "$zshrc"
fi

echo "PATH includes $dst/bin"
echo "Open a new terminal, or run: source ~/.zshrc"
