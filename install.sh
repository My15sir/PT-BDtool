#!/usr/bin/env bash
set -euo pipefail

START_TS="$(date +%s)"
SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
case "$SCRIPT_SOURCE" in
  ""|"-"|/dev/fd/*|/proc/self/fd/*|/dev/stdin)
    cat >&2 <<'EOF'
[ERROR] install.sh is running from a file descriptor/stdin path and cannot resolve offline bundle files.
[ERROR] Please run install.sh from a local PT-BDtool directory or extracted release bundle.
[HINT]  git clone https://github.com/My15sir/PT-BDtool.git && cd PT-BDtool && bash install.sh --offline
EOF
    exit 2
    ;;
esac
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
LANG_OVERRIDE=""
NON_INTERACTIVE=0
COPIED_COUNT=0
SKIPPED_COUNT=0

log() { printf '[install] %s\n' "$*"; }
err() { printf '[install][ERROR] %s\n' "$*" >&2; }

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

elapsed_since() {
  local since_ts="$1"
  local now_ts
  now_ts="$(date +%s)"
  printf '%ss' "$((now_ts - since_ts))"
}

copy_if_changed() {
  local src="$1"
  local dst="$2"
  local label="$3"
  mkdir -p "$(dirname "$dst")"
  if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
    log "skip (unchanged): $label"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    return 0
  fi
  cp -f "$src" "$dst"
  log "copied: $label"
  COPIED_COUNT=$((COPIED_COUNT + 1))
}

bundle_dep_status() {
  local missing=0
  local item=""
  for item in "$@"; do
    if [[ -x "$item" ]]; then
      log "dependency present: $(basename "$item") ($item)"
    else
      err "dependency missing: $(basename "$item") ($item)"
      missing=1
    fi
  done
  return "$missing"
}

should_skip_bundle_sync() {
  local src_bundle="$1"
  local dst_bundle="$2"
  local bin_name="" src_bin="" dst_bin="" src_sum="" dst_sum=""
  [[ -d "$dst_bundle/bin" && -d "$dst_bundle/lib" ]] || return 1
  find "$dst_bundle/lib" -maxdepth 1 -type f | grep -q . || return 1

  for bin_name in ffmpeg ffprobe mediainfo BDInfo; do
    src_bin="$src_bundle/bin/$bin_name"
    dst_bin="$dst_bundle/bin/$bin_name"
    [[ -x "$src_bin" && -x "$dst_bin" ]] || return 1
    src_sum="$(sha256_file "$src_bin")"
    dst_sum="$(sha256_file "$dst_bin")"
    [[ "$src_sum" == "$dst_sum" ]] || return 1
  done
  return 0
}

sync_bundle() {
  local src_bundle="$1"
  local dst_bundle="$2"
  if should_skip_bundle_sync "$src_bundle" "$dst_bundle"; then
    log "skip (bundle cached): $dst_bundle"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    return 0
  fi

  mkdir -p "$dst_bundle"
  cp -a "$src_bundle/bin" "$dst_bundle/"
  cp -a "$src_bundle/lib" "$dst_bundle/"
  log "copied: bundle bin/lib -> $dst_bundle"
  COPIED_COUNT=$((COPIED_COUNT + 1))
}

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
      shift
      ;;
    --online-legacy)
      echo "[ERROR] Online package-manager installation is disabled. Use offline bundle only." >&2
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

PRECHECK_TS="$(date +%s)"
log "precheck start"
if ! bundle_dep_status "${required_bundle_files[@]}"; then
  err "offline bundle dependencies are incomplete."
  err "Run: bash scripts/fetch-deps.sh && bash scripts/build-bundle.sh"
  exit 1
fi
log "precheck done (elapsed=$(elapsed_since "$PRECHECK_TS"))"

if [[ -w "/opt" || ${EUID:-$(id -u)} -eq 0 ]]; then
  INSTALL_ROOT="/opt/PT-BDtool"
else
  INSTALL_ROOT="$HOME/.local/share/pt-bdtool/PT-BDtool-app"
fi

INSTALL_TS="$(date +%s)"
log "install root: $INSTALL_ROOT"
mkdir -p "$INSTALL_ROOT/lib" "$INSTALL_ROOT/third_party/bundle/linux-amd64"
copy_if_changed "$SCRIPT_DIR/bdtool" "$INSTALL_ROOT/bdtool" "bdtool"
copy_if_changed "$SCRIPT_DIR/bdtool.sh" "$INSTALL_ROOT/bdtool.sh" "bdtool.sh"
copy_if_changed "$SCRIPT_DIR/ptbd-start.sh" "$INSTALL_ROOT/ptbd-start.sh" "ptbd-start.sh"
copy_if_changed "$SCRIPT_DIR/install.sh" "$INSTALL_ROOT/install.sh" "install.sh"
if [[ -f "$SCRIPT_DIR/README.md" ]]; then
  copy_if_changed "$SCRIPT_DIR/README.md" "$INSTALL_ROOT/README.md" "README.md"
else
  log "skip (missing optional file): README.md"
  SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
fi
copy_if_changed "$SCRIPT_DIR/lib/ui.sh" "$INSTALL_ROOT/lib/ui.sh" "lib/ui.sh"
copy_if_changed "$SCRIPT_DIR/lib/i18n.sh" "$INSTALL_ROOT/lib/i18n.sh" "lib/i18n.sh"
sync_bundle "$SCRIPT_DIR/third_party/bundle/linux-amd64" "$INSTALL_ROOT/third_party/bundle/linux-amd64"
chmod +x "$INSTALL_ROOT/bdtool" "$INSTALL_ROOT/bdtool.sh" "$INSTALL_ROOT/ptbd-start.sh" "$INSTALL_ROOT/install.sh"
log "install stage done (elapsed=$(elapsed_since "$INSTALL_TS"), copied=$COPIED_COUNT, skipped=$SKIPPED_COUNT)"

if [[ -w "/usr/local/bin" || ${EUID:-$(id -u)} -eq 0 ]]; then
  ln -sf "$INSTALL_ROOT/bdtool" /usr/local/bin/bdtool
  ln -sf "$INSTALL_ROOT/ptbd-start.sh" /usr/local/bin/ptbd-start
else
  mkdir -p "$HOME/.local/bin"
  ln -sf "$INSTALL_ROOT/bdtool" "$HOME/.local/bin/bdtool"
  ln -sf "$INSTALL_ROOT/ptbd-start.sh" "$HOME/.local/bin/ptbd-start"
  echo "[INFO] Ensure ~/.local/bin is in PATH" >&2
fi

log "offline install complete: $INSTALL_ROOT"
log "entrypoints: bdtool / ptbd-start"
log "total elapsed: $(elapsed_since "$START_TS")"

if [[ "$NON_INTERACTIVE" == "1" ]]; then
  if [[ -n "$LANG_OVERRIDE" ]]; then
    exec "$INSTALL_ROOT/bdtool" --non-interactive --lang "$LANG_OVERRIDE"
  fi
  exec "$INSTALL_ROOT/bdtool" --non-interactive
fi
