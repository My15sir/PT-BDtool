#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC2317
# This function is only reached via the ERR trap.
on_err() {
  local line="${1:-unknown}"
  local rc="${2:-1}"
  echo "[ERROR] Start workflow failed at line ${line} (rc=${rc})" >&2
  exit "$rc"
}
trap 'on_err "${LINENO}" "$?"' ERR

resolve_script_path() {
  local src="$1"
  local dir=""
  while [[ -L "$src" ]]; do
    dir="$(cd -P "$(dirname "$src")" && pwd)"
    src="$(readlink "$src")"
    [[ "$src" != /* ]] && src="$dir/$src"
  done
  echo "$src"
}

SCRIPT_PATH="$(resolve_script_path "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"
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
