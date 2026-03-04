#!/usr/bin/env bash
set -euo pipefail

on_err() {
  local rc="$?"
  local line="${1:-unknown}"
  echo "[ERROR] Start workflow failed at line ${line} (rc=${rc})" >&2
  exit "$rc"
}
trap 'on_err $LINENO' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/lib/ui.sh" ]]; then
  # shellcheck source=lib/ui.sh
  source "$SCRIPT_DIR/lib/ui.sh"
  setup_bundle_runtime "$SCRIPT_DIR"
fi

echo "================================"
echo "Starting PT-BDtool workflow..."
echo "================================"

if command -v bdtool >/dev/null 2>&1; then
  exec bdtool "$@"
fi

if [[ -x "$SCRIPT_DIR/bdtool" ]]; then
  exec "$SCRIPT_DIR/bdtool" "$@"
fi

if [[ -x "$SCRIPT_DIR/bdtool.sh" ]]; then
  exec "$SCRIPT_DIR/bdtool.sh" "$@"
fi

echo "[ERROR] Cannot find bdtool entrypoint." >&2
echo "Tried: \`bdtool\`, \`$SCRIPT_DIR/bdtool\`, \`$SCRIPT_DIR/bdtool.sh\`" >&2
exit 1
