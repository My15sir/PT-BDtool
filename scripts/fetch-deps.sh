#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOCK_FILE="${LOCK_FILE:-$SCRIPT_DIR/deps.env}"
BUNDLE_DIR="$ROOT_DIR/third_party/bundle/linux-amd64"
BIN_DIR="$BUNDLE_DIR/bin"
LIB_DIR="$BUNDLE_DIR/lib"
TMP_DIR="$ROOT_DIR/.tmp-fetch-deps"

PTBD_FETCH_TIMEOUT="${PTBD_FETCH_TIMEOUT:-60}"
PTBD_FETCH_RETRY="${PTBD_FETCH_RETRY:-2}"
PTBD_FETCH_MODE="${PTBD_FETCH_MODE:-auto}"  # auto|remote|system

start_ts="$(date +%s)"
success_count=0
fail_count=0

log() { printf '[fetch-deps] %s\n' "$*"; }
err() { printf '[fetch-deps][ERROR] %s\n' "$*" >&2; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "missing command: $1"; exit 1; }
}

validate_fetch_mode() {
  case "$PTBD_FETCH_MODE" in
    auto|remote|system) ;;
    *)
      err "invalid PTBD_FETCH_MODE=$PTBD_FETCH_MODE (use: auto|remote|system)"
      err "copy-paste fix: PTBD_FETCH_MODE=system bash scripts/fetch-deps.sh"
      exit 2
      ;;
  esac
}

print_mode_help() {
  log "mode=$PTBD_FETCH_MODE lock_file=$LOCK_FILE"
  log "mode behaviors:"
  log "  - system: only use binaries from PATH (system:// entries required)"
  log "  - remote: only download from http(s) URLs (system:// entries are rejected)"
  log "  - auto:   prefer URL behavior in lock file; http(s) download may fallback to system PATH"
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

verify_sha256() {
  local file="$1"
  local expected="$2"
  [[ "$expected" == "SKIP" ]] && return 0
  local actual
  actual="$(sha256_file "$file")"
  [[ "$actual" == "$expected" ]] || {
    err "sha256 mismatch: $file expected=$expected actual=$actual"
    return 1
  }
}

retry_download() {
  local url="$1"
  local out="$2"
  local i=0
  local max_try=$((PTBD_FETCH_RETRY + 1))
  while (( i < max_try )); do
    i=$((i + 1))
    if command -v curl >/dev/null 2>&1; then
      if timeout "${PTBD_FETCH_TIMEOUT}s" curl -fL --connect-timeout 10 -o "$out" "$url"; then
        return 0
      fi
    elif command -v wget >/dev/null 2>&1; then
      if timeout "${PTBD_FETCH_TIMEOUT}s" wget -O "$out" "$url"; then
        return 0
      fi
    else
      err "need curl or wget for remote fetch"
      return 1
    fi
    log "retry $i/$max_try for $url"
    sleep "$i"
  done
  return 1
}

copy_binary_and_libs() {
  local src_bin="$1"
  local dst_bin="$2"
  cp -f "$src_bin" "$dst_bin"
  chmod +x "$dst_bin"

  if command -v ldd >/dev/null 2>&1; then
    while IFS= read -r lib; do
      [[ -n "$lib" && -f "$lib" ]] || continue
      cp -f "$lib" "$LIB_DIR/$(basename "$lib")"
    done < <(ldd "$src_bin" 2>/dev/null | awk '{if ($3 ~ /^\//) print $3}')
  fi
}

fetch_one() {
  local name="$1" version="$2" url="$3" sha256="$4" target="$5"
  local target_path="$BIN_DIR/$target"
  local downloaded="$TMP_DIR/$name.download"

  log "processing $name version=$version"

  rm -f "$downloaded"
  if [[ "$PTBD_FETCH_MODE" == "remote" && "$url" == system://* ]]; then
    err "lock entry for $name is system:// but PTBD_FETCH_MODE=remote forbids PATH fallback"
    err "copy-paste fix A (recommended here): PTBD_FETCH_MODE=system bash scripts/fetch-deps.sh"
    err "copy-paste fix B: update scripts/deps.env to use http(s) URL for $name"
    return 1
  fi

  if [[ "$PTBD_FETCH_MODE" == "system" || "$url" == system://* ]]; then
    local cmd_name="${url#system://}"
    local src_bin
    src_bin="$(command -v "$cmd_name" 2>/dev/null || true)"
    if [[ -z "$src_bin" ]]; then
      err "$name not found in PATH ($cmd_name)"
      err "copy-paste fix A (Ubuntu/Debian sample):"
      err "  apt-get update && apt-get install -y ffmpeg mediainfo"
      err "copy-paste fix B (if using release bundle): skip fetch-deps and use extracted bundle + bash install.sh --offline"
      return 1
    fi
    copy_binary_and_libs "$src_bin" "$target_path"
    log "using system binary: $src_bin -> $target_path"
  else
    if ! retry_download "$url" "$downloaded"; then
      if [[ "$PTBD_FETCH_MODE" == "auto" ]]; then
        log "remote fetch failed for $name, fallback to system mode"
        local src_bin
        src_bin="$(command -v "$name" 2>/dev/null || true)"
        [[ -n "$src_bin" ]] || { err "fallback failed: $name not found in PATH"; return 1; }
        copy_binary_and_libs "$src_bin" "$target_path"
      else
        return 1
      fi
    else
      verify_sha256 "$downloaded" "$sha256"
      if file "$downloaded" | grep -qi 'gzip compressed\|tar archive\|xz compressed'; then
        local exdir="$TMP_DIR/extract-$name"
        rm -rf "$exdir"
        mkdir -p "$exdir"
        if file "$downloaded" | grep -qi 'xz compressed'; then
          tar -xJf "$downloaded" -C "$exdir"
        else
          tar -xzf "$downloaded" -C "$exdir"
        fi
        local found_bin
        found_bin="$(find "$exdir" -type f -name "$name" -perm -u+x | head -n1 || true)"
        [[ -n "$found_bin" ]] || found_bin="$(find "$exdir" -type f -perm -u+x | head -n1 || true)"
        [[ -n "$found_bin" ]] || { err "no executable found in archive for $name"; return 1; }
        copy_binary_and_libs "$found_bin" "$target_path"
      else
        copy_binary_and_libs "$downloaded" "$target_path"
      fi
      log "downloaded and installed: $name -> $target_path"
    fi
  fi

  [[ -x "$target_path" ]] || { err "target not executable: $target_path"; return 1; }
  return 0
}

main() {
  validate_fetch_mode
  need_cmd awk
  need_cmd sed
  need_cmd tar
  need_cmd timeout
  mkdir -p "$BIN_DIR" "$LIB_DIR" "$TMP_DIR"
  print_mode_help

  while IFS='|' read -r name version url sha256 target; do
    [[ -n "${name:-}" ]] || continue
    [[ "$name" =~ ^# ]] && continue
    if fetch_one "$name" "$version" "$url" "$sha256" "$target"; then
      success_count=$((success_count + 1))
    else
      fail_count=$((fail_count + 1))
      break
    fi
  done < "$LOCK_FILE"

  local end_ts elapsed
  end_ts="$(date +%s)"
  elapsed=$((end_ts - start_ts))

  log "summary: success=$success_count fail=$fail_count elapsed=${elapsed}s"
  if (( fail_count > 0 )); then
    err "dependency fetch failed under PTBD_FETCH_MODE=$PTBD_FETCH_MODE"
    err "copy-paste retry (system mode): PTBD_FETCH_MODE=system bash scripts/fetch-deps.sh"
    err "copy-paste retry (remote mode): PTBD_FETCH_MODE=remote bash scripts/fetch-deps.sh"
    exit 1
  fi

  log "bundle binaries:"
  find "$BIN_DIR" -maxdepth 1 -type f -printf '  - %f\n' | sort
  log "bundle libs count: $(find "$LIB_DIR" -maxdepth 1 -type f | wc -l)"
}

main "$@"
