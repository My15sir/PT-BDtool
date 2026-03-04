#!/usr/bin/env bash
set -euo pipefail

on_err() {
  local rc="$?"
  local line="${1:-unknown}"
  echo ""
  echo "[ERROR] Workflow failed at line ${line} (rc=${rc})"
  exit "$rc"
}
trap 'on_err $LINENO' ERR

log_step() {
  echo ""
  echo "$1"
}

echo "=============================="
echo "Running Codex workflow"
echo "=============================="

log_step "[1/4] Running tests..."
./codex-test.sh

log_step "[2/4] Tests passed"

log_step "[3/4] Creating git commit..."
git add .
git commit --allow-empty -m "auto: codex update"

log_step "[4/4] Pushing to GitHub..."
git push origin main

echo ""
echo "Workflow complete"
