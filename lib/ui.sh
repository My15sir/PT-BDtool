#!/usr/bin/env bash

: "${BDTOOL_CMD_TIMEOUT:=300}"

if [[ -t 2 ]]; then
  C_RED='\033[31m'
  C_CYAN='\033[36m'
  C_RESET='\033[0m'
  if command -v tput >/dev/null 2>&1; then
    COLORS="$(tput colors 2>/dev/null || echo 0)"
  else
    COLORS=0
  fi
  if [[ "$COLORS" =~ ^[0-9]+$ ]] && (( COLORS >= 256 )); then
    C_MENU='\033[38;5;223m'
  else
    C_MENU='\033[33m'
  fi
else
  C_RED=''
  C_CYAN=''
  C_MENU=''
  C_RESET=''
fi

screen() {
  printf "%s\n" "$*"
}

log_info() {
  printf "[INFO] %s\n" "$*" >&2
}

log_warn() {
  printf "[WARN] %s\n" "$*" >&2
}

log_err() {
  printf "[ERROR] %s\n" "$*" >&2
}

log_success() {
  printf "[SUCCESS] %s\n" "$*" >&2
}

screen_error() {
  printf "%b%s%b\n" "$C_RED" "$*" "$C_RESET"
}

section() {
  printf "%b==============================================================%b\n" "$C_CYAN" "$C_RESET"
  printf "%s\n" "$*"
  printf "%b==============================================================%b\n" "$C_CYAN" "$C_RESET"
}

menu_option() {
  printf "%b%s%b\n" "$C_MENU" "$*" "$C_RESET"
}

resolve_data_dir() {
  if [[ -n "${BDTOOL_DATA_DIR:-}" ]]; then
    printf "%s" "$BDTOOL_DATA_DIR"
    return 0
  fi

  if [[ -d "/opt/PT-BDtool" ]] && [[ -w "/opt/PT-BDtool" || ${EUID:-$(id -u)} -eq 0 ]]; then
    printf "%s" "/opt/PT-BDtool/bdtool-output"
    return 0
  fi

  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    printf "%s" "/opt/PT-BDtool/bdtool-output"
    return 0
  fi

  printf "%s" "$HOME/.local/share/pt-bdtool/bdtool-output"
}

resolve_effective_home() {
  local user_home="${HOME:-}"
  if [[ -n "${SUDO_USER:-}" ]]; then
    local sudo_home=""
    if command -v getent >/dev/null 2>&1; then
      sudo_home="$(getent passwd "$SUDO_USER" | awk -F: '{print $6}' | head -n1)"
    fi
    [[ -z "$sudo_home" ]] && sudo_home="/home/$SUDO_USER"
    user_home="$sudo_home"
  fi
  [[ -n "$user_home" ]] || return 1
  printf "%s" "$user_home"
}

resolve_default_download_dir() {
  if [[ -n "${BDTOOL_DOWNLOAD_DIR:-}" ]]; then
    mkdir -p "$BDTOOL_DOWNLOAD_DIR"
    [[ -d "$BDTOOL_DOWNLOAD_DIR" && -w "$BDTOOL_DOWNLOAD_DIR" ]] || return 1
    printf "%s" "$BDTOOL_DOWNLOAD_DIR"
    return 0
  fi

  local user_home=""
  user_home="$(resolve_effective_home)" || return 1

  local desktop_en="$user_home/Desktop"
  local desktop_zh="$user_home/桌面"
  local base_dir=""
  if [[ -d "$desktop_en" ]]; then
    base_dir="$desktop_en"
  elif [[ -d "$desktop_zh" ]]; then
    base_dir="$desktop_zh"
  else
    mkdir -p "$desktop_en"
    base_dir="$desktop_en"
  fi

  local target="$base_dir/PT-BDtool"
  mkdir -p "$target"
  local probe="$target/.bdtool_write_probe.$$"
  : > "$probe" || return 1
  rm -f "$probe"
  printf "%s" "$target"
}

setup_bundle_runtime() {
  local app_root="${1:-}"
  local bundle_dir="${PTBD_BUNDLE_DIR:-}"
  if [[ -z "$bundle_dir" && -n "$app_root" ]]; then
    bundle_dir="$app_root/third_party/bundle/linux-amd64"
  fi
  if [[ -z "$bundle_dir" ]]; then
    bundle_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/third_party/bundle/linux-amd64"
  fi

  if [[ -d "$bundle_dir/bin" ]]; then
    PATH="$bundle_dir/bin:$PATH"
    export PATH
  fi
  if [[ -d "$bundle_dir/lib" ]]; then
    if [[ -n "${LD_LIBRARY_PATH:-}" ]]; then
      LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:$bundle_dir/lib"
    else
      LD_LIBRARY_PATH="$bundle_dir/lib"
    fi
    export LD_LIBRARY_PATH
  fi
  if [[ -d "$bundle_dir" ]]; then
    BDTOOL_BUNDLE_DIR="$bundle_dir"
    export BDTOOL_BUNDLE_DIR
  fi
}

ensure_output_root() {
  OUTPUT_ROOT="$(resolve_data_dir)/output"
  ERROR_FILE="$OUTPUT_ROOT/last_error.txt"
  mkdir -p "$OUTPUT_ROOT"
}

write_error_file() {
  local reason="$1"
  local suggestion="$2"
  ensure_output_root
  {
    printf "reason: %s\n" "$reason"
    printf "suggestion: %s\n" "$suggestion"
  } > "$ERROR_FILE"
}

ensure_log_dir() {
  local root="${1:-$(pwd)}"
  BDTOOL_ROOT="$root"
  BDTOOL_LOG_DIR="$root/bdtool-output/logs"
  BDTOOL_RUN_LOG="$BDTOOL_LOG_DIR/run.log"
  mkdir -p "$BDTOOL_LOG_DIR"
  touch "$BDTOOL_RUN_LOG"
}

setup_log_redirection() {
  ensure_log_dir "${1:-$(pwd)}"
  if [[ "${BDTOOL_LOG_REDIRECTED:-0}" == "1" ]]; then
    return 0
  fi
  BDTOOL_LOG_REDIRECTED=1
  exec > >(tee -a "$BDTOOL_RUN_LOG") 2> >(tee -a "$BDTOOL_RUN_LOG" >&2)
}

execute_with_spinner() {
  local message="$1"
  shift
  ensure_log_dir "${BDTOOL_ROOT:-$(pwd)}"
  "$@" >> "$BDTOOL_RUN_LOG" 2>&1
  local rc=$?
  if [[ "$rc" -eq 0 ]]; then
    log_success "$message 完成"
  else
    log_err "$message 失败 (请查看 $BDTOOL_RUN_LOG)"
  fi
  return "$rc"
}

die() {
  local message="${1:-执行失败}"
  local code="${2:-1}"
  ensure_log_dir "${BDTOOL_ROOT:-$(pwd)}"
  log_err "$message"
  log_err "详情日志：$BDTOOL_RUN_LOG"
  exit "$code"
}

run_ext() {
  local timeout_s="${1:-$BDTOOL_CMD_TIMEOUT}"
  shift

  if command -v timeout >/dev/null 2>&1; then
    timeout --preserve-status "${timeout_s}s" "$@"
    return $?
  fi

  "$@" &
  local pid=$!
  local start_ts now_ts
  start_ts="$(date +%s)"

  while kill -0 "$pid" 2>/dev/null; do
    now_ts="$(date +%s)"
    if (( now_ts - start_ts >= timeout_s )); then
      kill -TERM "$pid" 2>/dev/null || true
      sleep 1
      kill -KILL "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      return 124
    fi
    sleep 1
  done

  wait "$pid"
  return $?
}

# Shared output layout resolver used by both `bdtool` and `bdtool.sh`.
# Exports:
# - BDTOOL_SOURCE_INFO_ROOT: "<source-parent>/信息"
# - BDTOOL_SOURCE_GEN_NAME:  "<source-dir-name>"
resolve_source_output_layout() {
  local src_type="${1:-}"
  local src_path="${2:-}"
  local base_dir=""

  [[ -n "$src_type" && -n "$src_path" ]] || return 1

  case "$src_type" in
    VIDEO|ISO)
      base_dir="$(dirname "$src_path")"
      ;;
    BDMV)
      if [[ "$(basename "$src_path")" == "BDMV" ]]; then
        base_dir="$(dirname "$src_path")"
      else
        base_dir="$src_path"
      fi
      ;;
    *)
      return 1
      ;;
  esac

  [[ -n "$base_dir" ]] || return 1
  BDTOOL_SOURCE_INFO_ROOT="$(dirname "$base_dir")/信息"
  BDTOOL_SOURCE_GEN_NAME="$(basename "$base_dir")"
  [[ -n "$BDTOOL_SOURCE_INFO_ROOT" && -n "$BDTOOL_SOURCE_GEN_NAME" ]]
}
