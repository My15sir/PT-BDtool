#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "$0")" && pwd)"
if [[ -x "$SCRIPT_DIR/ptbd-gui" ]]; then
  exec "$SCRIPT_DIR/ptbd-gui"
fi
exec python3 "$SCRIPT_DIR/ptbd-gui.py"
