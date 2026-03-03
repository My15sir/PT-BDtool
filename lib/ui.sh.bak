#!/usr/bin/env bash

# Shared UI helpers for PT-BDtool.

: "${BDTOOL_NO_PROMPT:=1}"
: "${BDTOOL_CMD_TIMEOUT:=300}"

if [[ -t 2 ]]; then
  UI_RED='\033[0;31m'
  UI_GREEN='\033[0;32m'
  UI_YELLOW='\033[0;33m'
  UI_BLUE='\033[0;34m'
  UI_CYAN='\033[0;36m'
  UI_NC='\033[0m'
else
  UI_RED=''
  UI_GREEN=''
  UI_YELLOW=''
  UI_BLUE=''
  UI_CYAN=''
  UI_NC=''
fi

log_info() { printf "%b[INFO]%b %s\n" "$UI_GREEN" "$UI_NC" "$*" >&2; }
log_warn() { printf "%b[WARN]%b %s\n" "$UI_YELLOW" "$UI_NC" "$*" >&2; }
log_err() { printf "%b[ERROR]%b %s\n" "$UI_RED" "$UI_NC" "$*" >&2; }
log_success() { printf "%b[SUCCESS]%b %s\n" "$UI_GREEN" "$UI_NC" "$*" >&2; }

hr() {
  printf "%b================================================================%b\n" "$UI_BLUE" "$UI_NC" >&2
}

section() {
  hr
  printf "%b%s%b\n" "$UI_CYAN" "$*" "$UI_NC" >&2
  hr
}

confirm() {
  local prompt="${1:-确认继续？}"
  local default="${2:-N}"
  local ans=""
  local hint="[y/N]"

  if [[ "$default" =~ ^[Yy]$ ]]; then
    hint="[Y/n]"
  fi

  if [[ "$BDTOOL_NO_PROMPT" == "1" || ! -t 0 ]]; then
    [[ "$default" =~ ^[Yy]$ ]] && return 0 || return 1
  fi

  while true; do
    read -r -p "  ▶ ${prompt} ${hint}: " ans < /dev/tty || true
    if [[ -z "$ans" ]]; then
      ans="$default"
    fi
    case "$ans" in
      [Yy]) return 0 ;;
      [Nn]) return 1 ;;
      *) log_warn "无效输入，请输入 y 或 n。" ;;
    esac
  done
}

prompt_with_default() {
  local prompt="${1:-请输入值}"
  local default="${2:-}"
  local value=""

  if [[ "$BDTOOL_NO_PROMPT" == "1" || ! -t 0 ]]; then
    printf "%s" "$default"
    return 0
  fi

  read -r -p "  ▶ ${prompt} [默认 ${default}]: " value < /dev/tty || true
  if [[ -z "$value" ]]; then
    value="$default"
  fi
  printf "%s" "$value"
}

validate_nonempty() {
  [[ -n "${1:-}" ]]
}

validate_int_range() {
  local value="${1:-}"
  local min="${2:-1}"
  local max="${3:-65535}"

  [[ "$value" =~ ^[0-9]+$ ]] || return 1
  (( value >= min && value <= max ))
}

ensure_log_dir() {
  local root="${1:-${BDTOOL_ROOT:-}}"
  if [[ -z "$root" ]]; then
    root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  fi

  BDTOOL_ROOT="$root"
  BDTOOL_LOG_DIR="$BDTOOL_ROOT/bdtool-output/logs"
  BDTOOL_RUN_LOG="$BDTOOL_LOG_DIR/run.log"

  mkdir -p "$BDTOOL_LOG_DIR"
  touch "$BDTOOL_RUN_LOG"
}

setup_log_redirection() {
  ensure_log_dir "${1:-${BDTOOL_ROOT:-}}"
  if [[ "${BDTOOL_LOG_REDIRECTED:-0}" == "1" ]]; then
    return 0
  fi
  BDTOOL_LOG_REDIRECTED=1
  exec > >(tee -a "$BDTOOL_RUN_LOG") 2> >(tee -a "$BDTOOL_RUN_LOG" >&2)
}

_run_command_with_timeout() {
  local timeout_s="$1"
  shift

  if command -v timeout >/dev/null 2>&1; then
    timeout --preserve-status "${timeout_s}s" "$@"
    return $?
  fi

  "$@" &
  local cmd_pid=$!
  local begin_ts
  begin_ts="$(date +%s)"

  while kill -0 "$cmd_pid" 2>/dev/null; do
    local now_ts
    now_ts="$(date +%s)"
    if (( now_ts - begin_ts >= timeout_s )); then
      kill -TERM "$cmd_pid" 2>/dev/null || true
      sleep 1
      kill -KILL "$cmd_pid" 2>/dev/null || true
      wait "$cmd_pid" 2>/dev/null || true
      return 124
    fi
    sleep 1
  done

  wait "$cmd_pid"
  return $?
}

run_cmd_logged() {
  local msg="$1"
  shift
  ensure_log_dir "${BDTOOL_ROOT:-}"

  local timeout_s="${BDTOOL_CMD_TIMEOUT:-300}"
  local ts_begin ts_end ret
  ts_begin="$(date '+%Y-%m-%d %H:%M:%S')"
  {
    printf "[%s] [CMD-START] %s | timeout=%ss | cmd=" "$ts_begin" "$msg" "$timeout_s"
    printf "%q " "$@"
    printf "\n"
  } >> "$BDTOOL_RUN_LOG"

  _run_command_with_timeout "$timeout_s" "$@" >> "$BDTOOL_RUN_LOG" 2>&1
  ret=$?

  ensure_log_dir "${BDTOOL_ROOT:-}"
  ts_end="$(date '+%Y-%m-%d %H:%M:%S')"
  if [[ "$ret" -eq 124 ]]; then
    printf "[%s] [TIMEOUT] %s | timeout=%ss\n" "$ts_end" "$msg" "$timeout_s" >> "$BDTOOL_RUN_LOG"
  fi
  printf "[%s] [CMD-END] %s | rc=%s\n" "$ts_end" "$msg" "$ret" >> "$BDTOOL_RUN_LOG"
  return "$ret"
}

execute_with_spinner() {
  local msg="$1"
  shift

  ensure_log_dir "${BDTOOL_ROOT:-}"

  run_cmd_logged "$msg" "$@" &
  local pid=$!
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local delay=0.1

  if [[ -t 2 ]]; then
    printf "\e[?25l" >&2
    while kill -0 "$pid" 2>/dev/null; do
      local head="${spin:0:1}"
      spin="${spin:1}${head}"
      printf "\r\033[K %b[%s]%b %s..." "$UI_CYAN" "$head" "$UI_NC" "$msg" >&2
      sleep "$delay"
    done
    printf "\e[?25h" >&2
  fi

  local ret=0
  wait "$pid" || ret=$?

  if [[ "$ret" -eq 0 ]]; then
    if [[ -t 2 ]]; then
      printf "\r\033[K %b[√]%b %s... 完成\n" "$UI_GREEN" "$UI_NC" "$msg" >&2
    else
      log_success "$msg 完成"
    fi
  elif [[ "$ret" -eq 124 ]]; then
    if [[ -t 2 ]]; then
      printf "\r\033[K %b[X]%b %s... 超时 (>${BDTOOL_CMD_TIMEOUT}s, 见 %s)\n" "$UI_RED" "$UI_NC" "$msg" "$BDTOOL_RUN_LOG" >&2
    else
      log_err "$msg 超时 (>${BDTOOL_CMD_TIMEOUT}s, 请查看 $BDTOOL_RUN_LOG)"
    fi
  else
    if [[ -t 2 ]]; then
      printf "\r\033[K %b[X]%b %s... 失败 (请查看 %s)\n" "$UI_RED" "$UI_NC" "$msg" "$BDTOOL_RUN_LOG" >&2
    else
      log_err "$msg 失败 (请查看 $BDTOOL_RUN_LOG)"
    fi
  fi

  return "$ret"
}

die() {
  local message="${1:-执行失败}"
  local code="${2:-1}"

  ensure_log_dir "${BDTOOL_ROOT:-}"
  log_err "$message"
  log_err "详情日志：$BDTOOL_RUN_LOG"
  exit "$code"
}
