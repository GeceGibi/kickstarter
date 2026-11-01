#!/bin/bash
set -euo pipefail

# Toolchain is already in the macos-tahoe-xcode VM. This only registers login startup.
root="$(cd "$(dirname "$0")" && pwd)"
"$root/kickstarter-vm/install.sh"
