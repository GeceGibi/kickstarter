#!/bin/bash
# Host login service. Runs a throwaway clone of base-macos. Never starts base-macos.

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

base="base-macos"
name="ci-macos"

drop() {
  tart stop "$name" >/dev/null 2>&1 || true
  tart delete "$name" >/dev/null 2>&1 || true
}

trap drop EXIT INT TERM

while true; do
  drop
  if tart clone "$base" "$name"; then
    tart run "$name" || true
  else
    echo "clone failed: $base -> $name" >&2
  fi
  drop
  sleep 10
done
