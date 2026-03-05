# PT-BDtool (English)

For beginner-first CN guide with full copy-paste flows, use `README.md`.

## Quick Start (Copy/Paste)

Purpose: clone, prepare offline bundle, install, and verify.
```bash
cd ~
git clone https://github.com/My15sir/PT-BDtool.git
cd PT-BDtool
bash scripts/fetch-deps.sh
bash scripts/build-bundle.sh
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
bdtool --help
```
Expected success: help output starts with `bdtool <path> [options]`.

## One-shot Self Check

Purpose: confirm install integrity and runtime commands.
```bash
export PATH="$HOME/.local/bin:$PATH"
set -e
command -v bdtool
command -v ptbd-start
bdtool --help >/dev/null
bdtool doctor
ptbd-start --help >/dev/null
echo "PT-BDtool self-check PASS"
```
Expected success: prints `PT-BDtool self-check PASS`.

## Common Error Fix

Purpose: fix stale wrappers (`/usr/local/bin/lib/ui.sh` not found or undefined function errors).
```bash
export PATH="$HOME/.local/bin:$PATH"
cd ~/PT-BDtool
bash scripts/fetch-deps.sh
bash scripts/build-bundle.sh
bash install.sh --offline
bdtool --help
```
Expected success: installer prints `post-install self-check done: PASS`.
