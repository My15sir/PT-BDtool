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
