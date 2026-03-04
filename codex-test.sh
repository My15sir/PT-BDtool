#!/usr/bin/env bash
set -euo pipefail

on_err() {
  local rc="$?"
  local line="${1:-unknown}"
  echo "[ERROR] Test workflow failed at line ${line} (rc=${rc})" >&2
  exit "$rc"
}
trap 'on_err $LINENO' ERR

echo "Running PT-BDtool tests..."

./full-test.sh

echo "Tests finished."
