#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT_DIR/bdtool-output/logs"
RUN_LOG="$LOG_DIR/run.log"
FULL_LOG="$LOG_DIR/full-test.log"
RESULTS_TSV="$LOG_DIR/full-test-results.tsv"
TMP_FULL_LOG="$ROOT_DIR/.full-test.log.tmp"
TMP_RESULTS_TSV="$ROOT_DIR/.full-test-results.tsv.tmp"

mkdir -p "$LOG_DIR"
touch "$RUN_LOG" "$FULL_LOG"
: > "$TMP_FULL_LOG"
: > "$TMP_RESULTS_TSV"

: > "$RESULTS_TSV"

TIMEOUT_SECONDS="${BDTOOL_CMD_TIMEOUT:-300}"

write_log() {
  mkdir -p "$LOG_DIR"
  touch "$FULL_LOG" "$TMP_FULL_LOG"
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$TMP_FULL_LOG" >/dev/null
  cp -f "$TMP_FULL_LOG" "$FULL_LOG"
}

run_step() {
  local name="$1"
  shift
  mkdir -p "$LOG_DIR"
  touch "$RUN_LOG" "$FULL_LOG" "$TMP_FULL_LOG" "$TMP_RESULTS_TSV"

  write_log "STEP START: $name"
  write_log "CMD: $*"

  local rc
  if command -v timeout >/dev/null 2>&1; then
    timeout --preserve-status "${TIMEOUT_SECONDS}s" "$@" >> "$TMP_FULL_LOG" 2>&1
    rc=$?
  else
    "$@" >> "$TMP_FULL_LOG" 2>&1 &
    local pid=$!
    local begin now
    begin="$(date +%s)"
    rc=0
    while kill -0 "$pid" 2>/dev/null; do
      now="$(date +%s)"
      if (( now - begin >= TIMEOUT_SECONDS )); then
        kill -TERM "$pid" 2>/dev/null || true
        sleep 1
        kill -KILL "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
        rc=124
        break
      fi
      sleep 1
    done
    if [[ "$rc" -ne 124 ]]; then
      wait "$pid"
      rc=$?
    fi
  fi

  local status="PASS"
  if [[ "$rc" -eq 124 ]]; then
    status="TIMEOUT"
    write_log "TIMEOUT: $name exceeded ${TIMEOUT_SECONDS}s"
    printf '[%s] [TIMEOUT] %s exceeded %ss\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$name" "$TIMEOUT_SECONDS" >> "$RUN_LOG"
  elif [[ "$rc" -ne 0 ]]; then
    status="FAIL"
  fi

  write_log "STEP END: $name status=$status rc=$rc"
  mkdir -p "$LOG_DIR"
  touch "$RESULTS_TSV" "$TMP_RESULTS_TSV"
  printf '%s\t%s\t%s\n' "$name" "$status" "$rc" >> "$TMP_RESULTS_TSV"
  cp -f "$TMP_RESULTS_TSV" "$RESULTS_TSV"
}

run_step "help" "$ROOT_DIR/ptbd" --help
run_step "doctor" "$ROOT_DIR/ptbd" doctor
run_step "install-dry" "$ROOT_DIR/ptbd" install
run_step "scan" "$ROOT_DIR/ptbd" scan
run_step "clean" "$ROOT_DIR/ptbd" clean
run_step "bad-args" "$ROOT_DIR/ptbd" unknown-command

write_log "FULL TEST COMPLETE"
cp -f "$TMP_FULL_LOG" "$FULL_LOG"
cp -f "$TMP_RESULTS_TSV" "$RESULTS_TSV"
