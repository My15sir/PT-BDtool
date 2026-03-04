#!/usr/bin/env bash
set -e

echo "=============================="
echo "Running Codex workflow"
echo "=============================="

echo ""
echo "[1/4] Running tests..."
./codex-test.sh

echo ""
echo "[2/4] Tests passed"

echo ""
echo "[3/4] Creating git commit..."

git add .

git commit -m "auto: codex update" || echo "Nothing to commit"

echo ""
echo "[4/4] Pushing to GitHub..."

git push origin main

echo ""
echo "Workflow complete"