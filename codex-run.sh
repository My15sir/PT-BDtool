#!/usr/bin/env bash
set -e

echo "=============================="
echo "Running Codex workflow"
echo "=============================="

echo ""
echo "[1/3] Running tests..."
./codex-test.sh

echo ""
echo "[2/3] Tests passed"

echo ""
echo "[3/3] Creating git commit..."

git add .

git commit -m "auto: codex update"

echo ""
echo "Workflow complete"
