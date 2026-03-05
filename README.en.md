# PT-BDtool (English)

For beginner-first CN guide with full copy-paste flows, use `README.md`.

## Quick Start (Copy/Paste)

Purpose: clone/update repo, install, and verify (stop immediately on error).
```bash
set -euo pipefail
cd ~
if [ -d PT-BDtool/.git ]; then
  cd PT-BDtool && git pull --ff-only
else
  git clone https://github.com/My15sir/PT-BDtool.git
  cd PT-BDtool
fi
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
bdtool --help
```
Expected success: help output is shown (`Usage` or `用法` line).

## Offline Install (Copy/Paste)

Purpose: install from release bundle and fail fast when the tarball is missing.
```bash
set -euo pipefail
cd ~
test -f PT-BDtool-linux-amd64.tar.gz
tar -xzf PT-BDtool-linux-amd64.tar.gz
cd PT-BDtool-linux-amd64
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
bdtool --help
```
Expected success: installer prints `post-install self-check done: PASS`.

## One-shot Self Check

Purpose: confirm install integrity and runtime commands.
```bash
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
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
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
cd ~/PT-BDtool
rm -f /usr/local/bin/bdtool /usr/local/bin/ptbd-start 2>/dev/null || true
rm -f "$HOME/.local/bin/bdtool" "$HOME/.local/bin/ptbd-start"
bash install.sh --offline
bdtool --help
```
Expected success: installer prints `post-install self-check done: PASS`.
