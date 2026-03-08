#!/usr/bin/env bash
set -euo pipefail

PTBD_REMOTE_HOST="${PTBD_REMOTE_HOST:-}"
PTBD_REMOTE_PORT="${PTBD_REMOTE_PORT:-22}"
PTBD_REMOTE_PASSWORD="${PTBD_REMOTE_PASSWORD:-}"
PTBD_REMOTE_PT_CMD="${PTBD_REMOTE_PT_CMD:-pt}"
PTBD_REMOTE_RETURN_PORT="${PTBD_REMOTE_RETURN_PORT:-18080}"
PTBD_LOCAL_HTTP_PORT="${PTBD_LOCAL_HTTP_PORT:-18080}"
PTBD_LOCAL_SAVE_DIR="${PTBD_LOCAL_SAVE_DIR:-}"
PTBD_SCAN_INCLUDE_ROOTS="${PTBD_SCAN_INCLUDE_ROOTS:-}"
PTBD_SCAN_EXCLUDE_ROOTS="${PTBD_SCAN_EXCLUDE_ROOTS:-}"
PTBD_AUTO_CLEANUP="${PTBD_AUTO_CLEANUP:-1}"
PTBD_KEEP_BRIDGE="${PTBD_KEEP_BRIDGE:-0}"

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"
UPLOAD_SERVER_SCRIPT="${SCRIPT_DIR}/scripts/remote-upload-server.py"

UPLOAD_SERVER_PID=""
TUNNEL_PID=""

log() { printf '[ptbd-remote] %s\n' "$*"; }
err() { printf '[ptbd-remote][ERROR] %s\n' "$*" >&2; }

usage() {
  cat <<'EOF'
Usage:
  ptbd-remote --host user@server [options]

What it does:
  1. Start a local receive server on this machine
  2. Create a reverse SSH tunnel to the VPS
  3. Open remote PT-BDtool menu
  4. After you select an item, remote generation / return / cleanup run automatically

Options:
  --host user@server        Remote SSH target
  --port N                  Remote SSH port (default: 22)
  --password TEXT           SSH password; if omitted, use SSH keys
  --remote-cmd CMD          Remote command to launch (default: pt)
  --save-dir DIR            Local receive directory (default: Desktop)
  --local-port N            Local HTTP server port (default: 18080)
  --remote-return-port N    Remote reverse tunnel port (default: 18080)
  --scan-include "DIRS"     Remote whitelist roots, separated by spaces or commas
  --scan-exclude "DIRS"     Remote extra exclude roots, separated by spaces or commas
  --keep-bridge             Keep local server and tunnel after command exits
  -h, --help                Show this help

Environment variables:
  PTBD_REMOTE_HOST
  PTBD_REMOTE_PORT
  PTBD_REMOTE_PASSWORD
  PTBD_REMOTE_PT_CMD
  PTBD_LOCAL_SAVE_DIR
  PTBD_SCAN_INCLUDE_ROOTS
  PTBD_SCAN_EXCLUDE_ROOTS
EOF
}

quote_sh() {
  printf "'%s'" "$(printf '%s' "${1:-}" | sed "s/'/'\\\\''/g")"
}

resolve_save_dir() {
  if [[ -n "$PTBD_LOCAL_SAVE_DIR" ]]; then
    mkdir -p "$PTBD_LOCAL_SAVE_DIR"
    printf '%s' "$PTBD_LOCAL_SAVE_DIR"
    return 0
  fi
  if [[ -d "$HOME/Desktop" ]]; then
    printf '%s' "$HOME/Desktop"
    return 0
  fi
  if [[ -d "$HOME/桌面" ]]; then
    printf '%s' "$HOME/桌面"
    return 0
  fi
  mkdir -p "$HOME/Desktop"
  printf '%s' "$HOME/Desktop"
}

cleanup() {
  local rc=$?
  if [[ "$PTBD_KEEP_BRIDGE" != "1" ]]; then
    [[ -n "$TUNNEL_PID" ]] && kill "$TUNNEL_PID" 2>/dev/null || true
    [[ -n "$UPLOAD_SERVER_PID" ]] && kill "$UPLOAD_SERVER_PID" 2>/dev/null || true
  fi
  exit "$rc"
}
trap cleanup EXIT INT TERM

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) PTBD_REMOTE_HOST="${2:-}"; shift 2 ;;
    --port) PTBD_REMOTE_PORT="${2:-}"; shift 2 ;;
    --password) PTBD_REMOTE_PASSWORD="${2:-}"; shift 2 ;;
    --remote-cmd) PTBD_REMOTE_PT_CMD="${2:-}"; shift 2 ;;
    --save-dir) PTBD_LOCAL_SAVE_DIR="${2:-}"; shift 2 ;;
    --local-port) PTBD_LOCAL_HTTP_PORT="${2:-}"; shift 2 ;;
    --remote-return-port) PTBD_REMOTE_RETURN_PORT="${2:-}"; shift 2 ;;
    --scan-include) PTBD_SCAN_INCLUDE_ROOTS="${2:-}"; shift 2 ;;
    --scan-exclude) PTBD_SCAN_EXCLUDE_ROOTS="${2:-}"; shift 2 ;;
    --keep-bridge) PTBD_KEEP_BRIDGE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown argument: $1"; usage; exit 2 ;;
  esac
done

[[ -n "$PTBD_REMOTE_HOST" ]] || { err "missing --host"; usage; exit 2; }
[[ -f "$UPLOAD_SERVER_SCRIPT" ]] || { err "missing upload server script: $UPLOAD_SERVER_SCRIPT"; exit 1; }
command -v ssh >/dev/null 2>&1 || { err "missing ssh"; exit 1; }
command -v python3 >/dev/null 2>&1 || { err "missing python3"; exit 1; }

LOCAL_SAVE_DIR="$(resolve_save_dir)"
log "local receive dir: $LOCAL_SAVE_DIR"

PTBD_SAVE_DIR="$LOCAL_SAVE_DIR" nohup python3 "$UPLOAD_SERVER_SCRIPT" "$PTBD_LOCAL_HTTP_PORT" >/tmp/ptbd_remote_upload_server.log 2>&1 &
UPLOAD_SERVER_PID="$!"
sleep 1
kill -0 "$UPLOAD_SERVER_PID" 2>/dev/null || { err "failed to start local upload server"; exit 1; }
log "local receive server started on 127.0.0.1:${PTBD_LOCAL_HTTP_PORT}"

SSH_CMD=(ssh -tt -p "$PTBD_REMOTE_PORT" -o ExitOnForwardFailure=yes -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -o StrictHostKeyChecking=accept-new)
if [[ -n "$PTBD_REMOTE_PASSWORD" ]]; then
  command -v sshpass >/dev/null 2>&1 || { err "password mode requires sshpass"; exit 1; }
  SSH_PREFIX=(sshpass -p "$PTBD_REMOTE_PASSWORD")
else
  SSH_PREFIX=()
fi

nohup "${SSH_PREFIX[@]}" ssh -N -p "$PTBD_REMOTE_PORT" -o ExitOnForwardFailure=yes -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -o StrictHostKeyChecking=accept-new -R "${PTBD_REMOTE_RETURN_PORT}:127.0.0.1:${PTBD_LOCAL_HTTP_PORT}" "$PTBD_REMOTE_HOST" >/tmp/ptbd_remote_tunnel.log 2>&1 &
TUNNEL_PID="$!"
sleep 3
kill -0 "$TUNNEL_PID" 2>/dev/null || { err "failed to create reverse SSH tunnel"; exit 1; }
log "reverse tunnel ready: remote 127.0.0.1:${PTBD_REMOTE_RETURN_PORT} -> local ${PTBD_LOCAL_HTTP_PORT}"

REMOTE_SCRIPT="export BDTOOL_RETURN_MODE=http; export BDTOOL_RETURN_HTTP_URL=$(quote_sh "http://127.0.0.1:${PTBD_REMOTE_RETURN_PORT}/upload"); export BDTOOL_AUTO_CLEANUP=$(quote_sh "$PTBD_AUTO_CLEANUP");"
if [[ -n "$PTBD_SCAN_INCLUDE_ROOTS" ]]; then
  REMOTE_SCRIPT="${REMOTE_SCRIPT} export BDTOOL_SCAN_INCLUDE_ROOTS=$(quote_sh "$PTBD_SCAN_INCLUDE_ROOTS");"
fi
if [[ -n "$PTBD_SCAN_EXCLUDE_ROOTS" ]]; then
  REMOTE_SCRIPT="${REMOTE_SCRIPT} export BDTOOL_SCAN_EXCLUDE_ROOTS=$(quote_sh "$PTBD_SCAN_EXCLUDE_ROOTS");"
fi
REMOTE_SCRIPT="${REMOTE_SCRIPT} exec $(quote_sh "$PTBD_REMOTE_PT_CMD")"

log "opening remote menu; select an item and the rest runs automatically"
"${SSH_PREFIX[@]}" "${SSH_CMD[@]}" "$PTBD_REMOTE_HOST" "bash -lc $(quote_sh "$REMOTE_SCRIPT")"

log "done; returned files should now be in: $LOCAL_SAVE_DIR"
