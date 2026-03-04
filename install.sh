#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFLINE_MODE=1
LANG_OVERRIDE=""
NON_INTERACTIVE=0

usage() {
  cat <<'USAGE'
Usage: bash install.sh [--offline] [--lang zh|en] [--non-interactive]

Options:
  --offline          Offline install only (default)
  --online-legacy    Kept for compatibility; not supported anymore
  --lang <code>      Pass language to bdtool after install
  --non-interactive  Run installed bdtool in non-interactive mode
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --offline)
      OFFLINE_MODE=1
      shift
      ;;
    --online-legacy)
      echo "[ERROR] Online apt installation is disabled. Use offline bundle only." >&2
      exit 2
      ;;
    --lang)
      LANG_OVERRIDE="${2:-}"
      shift 2
      ;;
    --lang=*)
      LANG_OVERRIDE="${1#*=}"
      shift
      ;;
    --non-interactive)
      NON_INTERACTIVE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

required_bundle_files=(
  "$SCRIPT_DIR/third_party/bundle/linux-amd64/bin/ffmpeg"
  "$SCRIPT_DIR/third_party/bundle/linux-amd64/bin/ffprobe"
  "$SCRIPT_DIR/third_party/bundle/linux-amd64/bin/mediainfo"
  "$SCRIPT_DIR/third_party/bundle/linux-amd64/bin/BDInfo"
)

for req in "${required_bundle_files[@]}"; do
  if [[ ! -x "$req" ]]; then
    echo "[ERROR] Offline dependency missing: $req" >&2
    echo "Run: bash scripts/fetch-deps.sh && bash scripts/build-bundle.sh" >&2
    exit 1
  fi
done

if [[ -w "/opt" || ${EUID:-$(id -u)} -eq 0 ]]; then
  INSTALL_ROOT="/opt/PT-BDtool"
else
  INSTALL_ROOT="$HOME/.local/share/pt-bdtool/PT-BDtool-app"
fi

mkdir -p "$INSTALL_ROOT/lib" "$INSTALL_ROOT/third_party/bundle/linux-amd64"
cp -f "$SCRIPT_DIR/bdtool" "$INSTALL_ROOT/bdtool"
cp -f "$SCRIPT_DIR/bdtool.sh" "$INSTALL_ROOT/bdtool.sh"
cp -f "$SCRIPT_DIR/ptbd-start.sh" "$INSTALL_ROOT/ptbd-start.sh"
cp -f "$SCRIPT_DIR/install.sh" "$INSTALL_ROOT/install.sh"
cp -f "$SCRIPT_DIR/README.md" "$INSTALL_ROOT/README.md" 2>/dev/null || true
cp -f "$SCRIPT_DIR/lib/ui.sh" "$INSTALL_ROOT/lib/ui.sh"
cp -f "$SCRIPT_DIR/lib/i18n.sh" "$INSTALL_ROOT/lib/i18n.sh"
cp -a "$SCRIPT_DIR/third_party/bundle/linux-amd64/bin" "$INSTALL_ROOT/third_party/bundle/linux-amd64/"
cp -a "$SCRIPT_DIR/third_party/bundle/linux-amd64/lib" "$INSTALL_ROOT/third_party/bundle/linux-amd64/"
chmod +x "$INSTALL_ROOT/bdtool" "$INSTALL_ROOT/bdtool.sh" "$INSTALL_ROOT/ptbd-start.sh" "$INSTALL_ROOT/install.sh"

if [[ -w "/usr/local/bin" || ${EUID:-$(id -u)} -eq 0 ]]; then
  ln -sf "$INSTALL_ROOT/bdtool" /usr/local/bin/bdtool
  ln -sf "$INSTALL_ROOT/ptbd-start.sh" /usr/local/bin/ptbd-start
else
  mkdir -p "$HOME/.local/bin"
  ln -sf "$INSTALL_ROOT/bdtool" "$HOME/.local/bin/bdtool"
  ln -sf "$INSTALL_ROOT/ptbd-start.sh" "$HOME/.local/bin/ptbd-start"
  echo "[INFO] Ensure ~/.local/bin is in PATH" >&2
fi

echo "[INFO] Offline install complete: $INSTALL_ROOT"
echo "[INFO] Entrypoints: bdtool / ptbd-start"

if [[ "$NON_INTERACTIVE" == "1" ]]; then
  if [[ -n "$LANG_OVERRIDE" ]]; then
    exec "$INSTALL_ROOT/bdtool" --non-interactive --lang "$LANG_OVERRIDE"
  fi
  exec "$INSTALL_ROOT/bdtool" --non-interactive
fi
