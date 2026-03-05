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

print_bootstrap_commands() {
  cat >&2 <<'EOF'
[HINT] Copy-paste (normal user):
  cd ~
  git clone https://github.com/My15sir/PT-BDtool.git
  cd PT-BDtool
  bash scripts/fetch-deps.sh
  bash scripts/build-bundle.sh
  bash install.sh --offline

[HINT] Copy-paste (root/sudo):
  cd /opt
  sudo git clone https://github.com/My15sir/PT-BDtool.git
  cd PT-BDtool
  sudo bash scripts/fetch-deps.sh
  sudo bash scripts/build-bundle.sh
  sudo bash install.sh --offline
EOF
}

preflight_install_context() {
  local missing=0
  local req=""
  local required_project_files=(
    "$SCRIPT_DIR/bdtool"
    "$SCRIPT_DIR/bdtool.sh"
    "$SCRIPT_DIR/ptbd-start.sh"
    "$SCRIPT_DIR/lib/ui.sh"
    "$SCRIPT_DIR/lib/i18n.sh"
    "$SCRIPT_DIR/scripts/fetch-deps.sh"
    "$SCRIPT_DIR/scripts/build-bundle.sh"
    "$SCRIPT_DIR/third_party/bundle/linux-amd64/bin"
  )

  for req in "${required_project_files[@]}"; do
    if [[ ! -e "$req" ]]; then
      err "missing required project file: $req"
      missing=1
    fi
  done

  if [[ "$missing" -ne 0 ]]; then
    err "install.sh must run from a complete local PT-BDtool repository or extracted offline bundle."
    print_bootstrap_commands
    exit 1
  fi

  if [[ "$PWD" != "$SCRIPT_DIR" ]]; then
    log "current directory is not project root; using script dir: $SCRIPT_DIR"
    log "if you see 'scripts/*.sh: No such file or directory', run: cd \"$SCRIPT_DIR\""
  fi
}

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

install_entrypoints() {
  local install_root="$1"
  local bin_dir="$2"
  local bdtool_link="$bin_dir/bdtool"
  local start_link="$bin_dir/ptbd-start"

  mkdir -p "$bin_dir"
  # Force-replace stale copied wrappers (regular files) from old versions.
  [[ -e "$bdtool_link" && ! -L "$bdtool_link" ]] && rm -f "$bdtool_link"
  [[ -e "$start_link" && ! -L "$start_link" ]] && rm -f "$start_link"

  ln -sfn "$install_root/bdtool" "$bdtool_link"
  ln -sfn "$install_root/ptbd-start.sh" "$start_link"
}

post_install_self_check() {
  local install_root="$1"
  local bin_dir="$2"
  local fail=0
  local f=""
  local resolved_bdtool=""
  local resolved_start=""
  local required_files=(
    "$install_root/bdtool"
    "$install_root/bdtool.sh"
    "$install_root/ptbd-start.sh"
    "$install_root/lib/ui.sh"
    "$install_root/lib/i18n.sh"
    "$install_root/third_party/bundle/linux-amd64/bin/ffmpeg"
    "$install_root/third_party/bundle/linux-amd64/bin/ffprobe"
    "$install_root/third_party/bundle/linux-amd64/bin/mediainfo"
    "$install_root/third_party/bundle/linux-amd64/bin/BDInfo"
  )

  log "post-install self-check start"
  for f in "${required_files[@]}"; do
    if [[ -e "$f" ]]; then
      log "self-check ok: $f"
    else
      err "self-check missing: $f"
      fail=1
    fi
  done

  if [[ -x "$bin_dir/bdtool" ]]; then
    log "self-check ok: entrypoint $bin_dir/bdtool"
  else
    err "self-check missing entrypoint: $bin_dir/bdtool"
    fail=1
  fi
  if [[ -x "$bin_dir/ptbd-start" ]]; then
    log "self-check ok: entrypoint $bin_dir/ptbd-start"
  else
    err "self-check missing entrypoint: $bin_dir/ptbd-start"
    fail=1
  fi

  if ! "$install_root/bdtool" --help >/dev/null 2>&1; then
    err "self-check failed: $install_root/bdtool --help"
    fail=1
  fi
  if ! "$install_root/ptbd-start.sh" --help >/dev/null 2>&1; then
    err "self-check failed: $install_root/ptbd-start.sh --help"
    fail=1
  fi
  if ! "$bin_dir/bdtool" --help >/dev/null 2>&1; then
    err "self-check failed: $bin_dir/bdtool --help"
    fail=1
  fi
  if ! "$bin_dir/ptbd-start" --help >/dev/null 2>&1; then
    err "self-check failed: $bin_dir/ptbd-start --help"
    fail=1
  fi

  resolved_bdtool="$(command -v bdtool 2>/dev/null || true)"
  if [[ -n "$resolved_bdtool" && "$resolved_bdtool" != "$bin_dir/bdtool" ]]; then
    err "PATH entry mismatch: command -v bdtool -> $resolved_bdtool (expected $bin_dir/bdtool)"
    err "copy-paste fix: rm -f \"$resolved_bdtool\" && hash -r && \"$bin_dir/bdtool\" --help"
    fail=1
  fi
  resolved_start="$(command -v ptbd-start 2>/dev/null || true)"
  if [[ -n "$resolved_start" && "$resolved_start" != "$bin_dir/ptbd-start" ]]; then
    err "PATH entry mismatch: command -v ptbd-start -> $resolved_start (expected $bin_dir/ptbd-start)"
    err "copy-paste fix: rm -f \"$resolved_start\" && hash -r && \"$bin_dir/ptbd-start\" --help"
    fail=1
  fi

  if [[ "$fail" -ne 0 ]]; then
    err "post-install self-check failed."
    cat >&2 <<EOF
[HINT] Copy-paste fix:
  cd "$SCRIPT_DIR"
  rm -f "$bin_dir/bdtool" "$bin_dir/ptbd-start"
  bash install.sh --offline
  "$bin_dir/bdtool" --help
EOF
    {
      echo "[DIAG] command -v bdtool: $(command -v bdtool 2>/dev/null || echo missing)"
      echo "[DIAG] command -v ptbd-start: $(command -v ptbd-start 2>/dev/null || echo missing)"
      [[ -e "$bin_dir/bdtool" ]] && ls -l "$bin_dir/bdtool" || echo "[DIAG] missing: $bin_dir/bdtool"
      [[ -e "$bin_dir/ptbd-start" ]] && ls -l "$bin_dir/ptbd-start" || echo "[DIAG] missing: $bin_dir/ptbd-start"
    } >&2
    exit 1
  fi

  log "post-install self-check done: PASS"
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

preflight_install_context

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
  err "Fix option A (if ffmpeg/ffprobe/mediainfo/BDInfo already installed):"
  err "  bash scripts/fetch-deps.sh && bash scripts/build-bundle.sh"
  err "Fix option B (if they are NOT installed): use official release tarball then run install.sh --offline."
  exit 1
fi
log "precheck done (elapsed=$(elapsed_since "$PRECHECK_TS"))"

if [[ -w "/opt" || ${EUID:-$(id -u)} -eq 0 ]]; then
  INSTALL_ROOT="${PTBD_INSTALL_ROOT:-/opt/PT-BDtool}"
else
  INSTALL_ROOT="${PTBD_INSTALL_ROOT:-$HOME/.local/share/pt-bdtool/PT-BDtool-app}"
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
  BIN_DIR="${PTBD_BIN_DIR:-/usr/local/bin}"
else
  BIN_DIR="${PTBD_BIN_DIR:-$HOME/.local/bin}"
fi
install_entrypoints "$INSTALL_ROOT" "$BIN_DIR"
# Refresh command lookup cache so post-check sees the new symlink entrypoints.
hash -r 2>/dev/null || true
if [[ "$BIN_DIR" == "$HOME/.local/bin" ]]; then
  echo "[INFO] Ensure ~/.local/bin is in PATH" >&2
fi

post_install_self_check "$INSTALL_ROOT" "$BIN_DIR"

log "offline install complete: $INSTALL_ROOT"
log "entrypoints: $BIN_DIR/bdtool / $BIN_DIR/ptbd-start"
log "total elapsed: $(elapsed_since "$START_TS")"

if [[ "$NON_INTERACTIVE" == "1" ]]; then
  if [[ -n "$LANG_OVERRIDE" ]]; then
    exec "$INSTALL_ROOT/bdtool" --non-interactive --lang "$LANG_OVERRIDE"
  fi
  exec "$INSTALL_ROOT/bdtool" --non-interactive
fi
