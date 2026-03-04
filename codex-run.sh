#!/usr/bin/env bash
set -euo pipefail

echo "=============================="
echo "Running Codex workflow"
echo "=============================="

echo ""
echo "[1/4] Running tests..."
./codex-test.sh

echo ""
echo "[2/4] Tests passed"

if [[ "${CODEX_RUN_GIT:-0}" == "1" ]]; then
  echo ""
  echo "[3/4] Creating git commit..."
  git add .
  git commit -m "auto: codex update" || echo "Nothing to commit"

  echo ""
  echo "[4/4] Pushing to GitHub..."
  git push origin main
else
  echo ""
  echo "[3/4] Skipping git commit (set CODEX_RUN_GIT=1 to enable)"
  echo "[4/4] Skipping git push (set CODEX_RUN_GIT=1 to enable)"
fi

echo ""
echo "Workflow complete"
