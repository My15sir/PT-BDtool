#!/usr/bin/env bash
set -euo pipefail

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
CLI_BIN="${BDTOOL_TEST_BIN:-}"

if [[ -z "$CLI_BIN" ]]; then
  if [[ -x "$ROOT_DIR/bdtool.sh" ]]; then
    CLI_BIN="$ROOT_DIR/bdtool.sh"
  elif [[ -x "$ROOT_DIR/bdtool" ]]; then
    CLI_BIN="$ROOT_DIR/bdtool"
  else
    echo "No testable CLI entry found. Expected bdtool.sh or bdtool in $ROOT_DIR" >&2
    exit 1
  fi
fi

write_log() {
  mkdir -p "$LOG_DIR"
  touch "$FULL_LOG" "$TMP_FULL_LOG"
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$TMP_FULL_LOG" >/dev/null
  cp -f "$TMP_FULL_LOG" "$FULL_LOG"
}

run_step() {
  local name="$1"
  local expect_mode="${2:-success}"
  shift 2
  case "$expect_mode" in
    success|fail) ;;
    *)
      write_log "Invalid expect_mode=$expect_mode for step=$name"
      return 2
      ;;
  esac

  local status expected_desc
  if [[ "$expect_mode" == "fail" ]]; then
    expected_desc="non-zero exit"
  else
    expected_desc="zero exit"
  fi

  write_log "EXPECT: $expected_desc"

  mkdir -p "$LOG_DIR"
  touch "$RUN_LOG" "$FULL_LOG" "$TMP_FULL_LOG" "$TMP_RESULTS_TSV"

  write_log "STEP START: $name"
  write_log "CMD: $*"

  local rc
  set +e
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
  set -e

  status="PASS"
  if [[ "$rc" -eq 124 ]]; then
    status="TIMEOUT"
    write_log "TIMEOUT: $name exceeded ${TIMEOUT_SECONDS}s"
    printf '[%s] [TIMEOUT] %s exceeded %ss\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$name" "$TIMEOUT_SECONDS" >> "$RUN_LOG"
  elif [[ "$expect_mode" == "success" && "$rc" -ne 0 ]]; then
    status="FAIL"
  elif [[ "$expect_mode" == "fail" && "$rc" -eq 0 ]]; then
    status="FAIL"
  fi

  write_log "STEP END: $name status=$status rc=$rc"
  mkdir -p "$LOG_DIR"
  touch "$RESULTS_TSV" "$TMP_RESULTS_TSV"
  printf '%s\t%s\t%s\n' "$name" "$status" "$rc" >> "$TMP_RESULTS_TSV"
  cp -f "$TMP_RESULTS_TSV" "$RESULTS_TSV"
}

run_step "help" success "$CLI_BIN" --help
run_step "version" success "$CLI_BIN" --version
run_step "doctor" success "$CLI_BIN" doctor
run_step "scan-dry-invalid-input" fail "$CLI_BIN" "$ROOT_DIR/bdtool.sh" --mode dry --out "$ROOT_DIR/bdtool-output/test-run"
run_step "clean" success "$CLI_BIN" clean
run_step "bad-args" fail "$CLI_BIN" unknown-command

write_log "FULL TEST COMPLETE"
cp -f "$TMP_FULL_LOG" "$FULL_LOG"
cp -f "$TMP_RESULTS_TSV" "$RESULTS_TSV"

if awk -F '\t' '$2 != "PASS"{found=1} END{exit found ? 0 : 1}' "$RESULTS_TSV"; then
  write_log "FULL TEST RESULT: FAIL (see $RESULTS_TSV)"
  exit 1
fi

write_log "FULL TEST RESULT: PASS"
