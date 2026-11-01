#!/bin/bash
# Host login service. Runs a throwaway clone of base-macos. Never starts base-macos.
# A running ci-macos is left alone. The clone is deleted only after it stops.

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

base="base-macos"
name="ci-macos"

running() {
  tart get "$name" --format json 2>/dev/null | grep -q '"Running" *: *true'
}

while true; do
  if running; then
    while running; do
      sleep 10
    done
  fi
  tart delete "$name" >/dev/null 2>&1 || true
  if tart clone "$base" "$name"; then
    tart run "$name" || true
    tart delete "$name" >/dev/null 2>&1 || true
  else
    echo "clone failed: $base -> $name" >&2
  fi
  sleep 10
done
