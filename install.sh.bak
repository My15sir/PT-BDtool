#!/usr/bin/env bash
set -Euo pipefail

ORIG_ARGS=("$@")
SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

BOOT_TIMEOUT="${PTBD_BOOTSTRAP_TIMEOUT:-300}"
BOOT_RETRY_MAX="${PTBD_BOOTSTRAP_RETRY:-3}"
APT_TIMEOUT="${APT_TIMEOUT:-300}"
APT_RETRY_MAX="${APT_RETRY_MAX:-3}"
APT_LOCK_WAIT="${APT_LOCK_WAIT:-60}"
APT_QUIET="${APT_QUIET:-1}"
BOOT_URL_BASE="https://github.com/My15sir/PT-BDtool/archive/refs/heads"
BOOT_TARBALL_URL="${PTBD_BOOTSTRAP_TARBALL_URL:-$BOOT_URL_BASE/main.tar.gz}"
BOOT_ZIPBALL_URL="${PTBD_BOOTSTRAP_ZIPBALL_URL:-$BOOT_URL_BASE/main.zip}"
BOOT_GIT_URL="${PTBD_BOOTSTRAP_GIT_URL:-https://github.com/My15sir/PT-BDtool.git}"

bootstrap_msg() {
  printf "[%s] [bootstrap] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2
}

run_ext_boot() {
  local timeout_s="${1:-300}"
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
}

bootstrap_debug() {
  local line="$*"
  printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$line" >> "$BOOT_DEBUG_LOG"
}

classify_bootstrap_issue() {
  local rc="$1"
  local http_code="$2"
  local err_file="$3"
  local err_txt=""

  err_txt="$(tail -n 200 "$err_file" 2>/dev/null || true)"

  if [[ "$rc" == "124" ]] || echo "$err_txt" | grep -Eqi 'timed out|operation timed out|connection timed out'; then
    BOOT_ISSUE="超时"
    BOOT_HINT="网络不通/受限或需代理。可配置代理后重试。"
    return 0
  fi

  if echo "$err_txt" | grep -Eqi 'Could not resolve host|Name or service not known|Temporary failure in name resolution|DNS'; then
    BOOT_ISSUE="DNS 解析失败"
    BOOT_HINT="请检查 /etc/resolv.conf，确认 DNS 可用。"
    return 0
  fi

  if echo "$err_txt" | grep -Eqi 'SSL certificate problem|certificate verify failed|TLS|x509'; then
    BOOT_ISSUE="TLS/证书失败"
    BOOT_HINT="请安装/更新 ca-certificates 后重试。"
    return 0
  fi

  if [[ "$http_code" == "403" || "$http_code" == "404" ]]; then
    BOOT_ISSUE="HTTP ${http_code}"
    BOOT_HINT="请检查 URL 是否正确、分支名是否为 main。"
    return 0
  fi

  if echo "$err_txt" | grep -Eqi 'command not found|No such file or directory'; then
    BOOT_ISSUE="命令缺失"
    BOOT_HINT="请安装 git/curl/wget/tar/unzip 后重试。"
    return 0
  fi

  BOOT_ISSUE="未知错误"
  BOOT_HINT="请查看调试日志并按离线方案安装。"
}

run_with_retry_timeout() {
  local label="$1"
  local stdout_file="$2"
  local stderr_file="$3"
  shift 3

  local attempt rc sleep_s
  : > "$stdout_file"
  : > "$stderr_file"

  for attempt in 1 2 3; do
    bootstrap_debug "$label attempt=$attempt cmd=$*"

    if run_ext_boot "$BOOT_TIMEOUT" "$@" >"$stdout_file" 2>"$stderr_file"; then
      bootstrap_debug "$label success attempt=$attempt"
      return 0
    fi

    rc=$?
    bootstrap_debug "$label failed attempt=$attempt rc=$rc"
    tail -n 50 "$stderr_file" >> "$BOOT_DEBUG_LOG" 2>/dev/null || true

    if (( attempt >= BOOT_RETRY_MAX )); then
      return "$rc"
    fi

    sleep_s=$((2 ** (attempt - 1)))
    bootstrap_debug "$label backoff=${sleep_s}s"
    sleep "$sleep_s"
  done

  return 1
}

extract_to_stable_repo_dir() {
  local tmp_root="$1"
  local extracted="$2"
  local repo_dir="$tmp_root/PT-BDtool"

  [[ -n "$extracted" && -d "$extracted" ]] || return 1

  if [[ "$extracted" != "$repo_dir" ]]; then
    rm -rf "$repo_dir" 2>/dev/null || true
    mv "$extracted" "$repo_dir"
  fi

  [[ -f "$repo_dir/install.sh" && -f "$repo_dir/lib/ui.sh" ]]
}

detect_network() {
  local ok=0

  if command -v curl >/dev/null 2>&1; then
    if run_ext_boot 10 curl -I -fsSL https://github.com >/dev/null 2>"$BOOT_TMP_ERR"; then
      ok=1
      bootstrap_msg "网络检查 github.com：可达"
    else
      bootstrap_debug "network github.com failed rc=$?"
      tail -n 20 "$BOOT_TMP_ERR" >> "$BOOT_DEBUG_LOG" 2>/dev/null || true
      bootstrap_msg "网络检查 github.com：不可达"
    fi

    if run_ext_boot 10 curl -I -fsSL https://raw.githubusercontent.com >/dev/null 2>"$BOOT_TMP_ERR"; then
      ok=1
      bootstrap_msg "网络检查 raw.githubusercontent.com：可达"
    else
      bootstrap_debug "network raw.githubusercontent.com failed rc=$?"
      tail -n 20 "$BOOT_TMP_ERR" >> "$BOOT_DEBUG_LOG" 2>/dev/null || true
      bootstrap_msg "网络检查 raw.githubusercontent.com：不可达"
    fi
  elif command -v wget >/dev/null 2>&1; then
    if run_ext_boot 10 wget -q --spider https://github.com 2>"$BOOT_TMP_ERR"; then
      ok=1
      bootstrap_msg "网络检查 github.com：可达"
    else
      bootstrap_debug "network github.com failed rc=$?"
      tail -n 20 "$BOOT_TMP_ERR" >> "$BOOT_DEBUG_LOG" 2>/dev/null || true
      bootstrap_msg "网络检查 github.com：不可达"
    fi
  else
    bootstrap_msg "未找到 curl/wget，跳过网络检查。"
  fi

  return $((ok == 1 ? 0 : 1))
}

try_git_clone() {
  local tmp_root="$1"
  local repo_dir="$tmp_root/PT-BDtool"

  if [[ "${PTBD_BOOTSTRAP_FORCE_NO_GIT:-0}" == "1" ]]; then
    bootstrap_msg "策略1 git clone：已强制跳过（PTBD_BOOTSTRAP_FORCE_NO_GIT=1）"
    return 1
  fi

  if ! command -v git >/dev/null 2>&1; then
    bootstrap_msg "策略1 git clone：跳过（未安装 git）"
    return 1
  fi

  bootstrap_msg "策略1/3：尝试 git clone..."
  rm -rf "$repo_dir" 2>/dev/null || true

  if run_with_retry_timeout "git_clone" "$BOOT_TMP_OUT" "$BOOT_TMP_ERR" git clone --depth=1 --branch main "$BOOT_GIT_URL" "$repo_dir"; then
    bootstrap_msg "策略1 git clone：成功"
    echo "$repo_dir"
    return 0
  fi

  classify_bootstrap_issue "$?" "" "$BOOT_TMP_ERR"
  bootstrap_msg "策略1 git clone 失败：$BOOT_ISSUE。$BOOT_HINT"
  bootstrap_debug "git_clone stderr(last20):"
  tail -n 20 "$BOOT_TMP_ERR" >> "$BOOT_DEBUG_LOG" 2>/dev/null || true
  return 1
}

try_tarball() {
  local tmp_root="$1"
  local tarball="$tmp_root/repo.tar.gz"
  local http_code=""
  local rc=0

  bootstrap_msg "策略2/3：尝试 tarball 下载..."

  if command -v curl >/dev/null 2>&1; then
    local attempt sleep_s
    for attempt in 1 2 3; do
      : > "$BOOT_TMP_ERR"
      http_code="$(run_ext_boot "$BOOT_TIMEOUT" curl -fSL --connect-timeout 10 --max-time "$BOOT_TIMEOUT" -o "$tarball" -w '%{http_code}' "$BOOT_TARBALL_URL" 2>"$BOOT_TMP_ERR" || true)"
      rc=$?
      bootstrap_debug "tarball curl attempt=$attempt rc=$rc http=$http_code"
      tail -n 30 "$BOOT_TMP_ERR" >> "$BOOT_DEBUG_LOG" 2>/dev/null || true
      if [[ "$rc" -eq 0 && -s "$tarball" ]]; then
        break
      fi
      if (( attempt < BOOT_RETRY_MAX )); then
        sleep_s=$((2 ** (attempt - 1)))
        sleep "$sleep_s"
      fi
    done
  elif command -v wget >/dev/null 2>&1; then
    if ! run_with_retry_timeout "tarball_wget" "$BOOT_TMP_OUT" "$BOOT_TMP_ERR" wget -O "$tarball" "$BOOT_TARBALL_URL"; then
      rc=$?
      http_code="$(grep -Eo ' [0-9]{3} ' "$BOOT_TMP_ERR" | tr -d ' ' | tail -n1 || true)"
    else
      rc=0
    fi
  else
    bootstrap_msg "策略2 tarball：跳过（未安装 curl/wget）"
    return 1
  fi

  if [[ "$rc" -ne 0 || ! -s "$tarball" ]]; then
    classify_bootstrap_issue "$rc" "$http_code" "$BOOT_TMP_ERR"
    bootstrap_msg "策略2 tarball 失败：$BOOT_ISSUE。$BOOT_HINT"
    return 1
  fi

  if ! command -v tar >/dev/null 2>&1; then
    bootstrap_msg "策略2 tarball 失败：缺少 tar。请安装 tar 后重试。"
    return 1
  fi

  rm -rf "$tmp_root"/PT-BDtool-* "$tmp_root/PT-BDtool" 2>/dev/null || true
  if ! run_with_retry_timeout "tar_extract" "$BOOT_TMP_OUT" "$BOOT_TMP_ERR" tar -xzf "$tarball" -C "$tmp_root"; then
    classify_bootstrap_issue "$?" "" "$BOOT_TMP_ERR"
    bootstrap_msg "策略2 tarball 解压失败：$BOOT_ISSUE。$BOOT_HINT"
    return 1
  fi

  local extracted
  extracted="$(find "$tmp_root" -maxdepth 1 -type d -name 'PT-BDtool-*' | head -n 1 || true)"
  if extract_to_stable_repo_dir "$tmp_root" "$extracted"; then
    bootstrap_msg "策略2 tarball：成功"
    echo "$tmp_root/PT-BDtool"
    return 0
  fi

  bootstrap_msg "策略2 tarball 失败：解压后目录无效。"
  return 1
}

try_zipball() {
  local tmp_root="$1"
  local zipball="$tmp_root/repo.zip"
  local http_code=""
  local rc=0

  bootstrap_msg "策略3/3：尝试 zipball 下载..."

  if command -v curl >/dev/null 2>&1; then
    local attempt sleep_s
    for attempt in 1 2 3; do
      : > "$BOOT_TMP_ERR"
      http_code="$(run_ext_boot "$BOOT_TIMEOUT" curl -fSL --connect-timeout 10 --max-time "$BOOT_TIMEOUT" -o "$zipball" -w '%{http_code}' "$BOOT_ZIPBALL_URL" 2>"$BOOT_TMP_ERR" || true)"
      rc=$?
      bootstrap_debug "zipball curl attempt=$attempt rc=$rc http=$http_code"
      tail -n 30 "$BOOT_TMP_ERR" >> "$BOOT_DEBUG_LOG" 2>/dev/null || true
      if [[ "$rc" -eq 0 && -s "$zipball" ]]; then
        break
      fi
      if (( attempt < BOOT_RETRY_MAX )); then
        sleep_s=$((2 ** (attempt - 1)))
        sleep "$sleep_s"
      fi
    done
  elif command -v wget >/dev/null 2>&1; then
    if ! run_with_retry_timeout "zipball_wget" "$BOOT_TMP_OUT" "$BOOT_TMP_ERR" wget -O "$zipball" "$BOOT_ZIPBALL_URL"; then
      rc=$?
      http_code="$(grep -Eo ' [0-9]{3} ' "$BOOT_TMP_ERR" | tr -d ' ' | tail -n1 || true)"
    else
      rc=0
    fi
  else
    bootstrap_msg "策略3 zipball：跳过（未安装 curl/wget）"
    return 1
  fi

  if [[ "$rc" -ne 0 || ! -s "$zipball" ]]; then
    classify_bootstrap_issue "$rc" "$http_code" "$BOOT_TMP_ERR"
    bootstrap_msg "策略3 zipball 失败：$BOOT_ISSUE。$BOOT_HINT"
    return 1
  fi

  if ! command -v unzip >/dev/null 2>&1; then
    bootstrap_msg "策略3 zipball 失败：缺少 unzip。请安装 unzip 后重试。"
    return 1
  fi

  rm -rf "$tmp_root"/PT-BDtool-* "$tmp_root/PT-BDtool" 2>/dev/null || true
  if ! run_with_retry_timeout "zip_extract" "$BOOT_TMP_OUT" "$BOOT_TMP_ERR" unzip -q "$zipball" -d "$tmp_root"; then
    classify_bootstrap_issue "$?" "" "$BOOT_TMP_ERR"
    bootstrap_msg "策略3 zipball 解压失败：$BOOT_ISSUE。$BOOT_HINT"
    return 1
  fi

  local extracted
  extracted="$(find "$tmp_root" -maxdepth 1 -type d -name 'PT-BDtool-*' | head -n 1 || true)"
  if extract_to_stable_repo_dir "$tmp_root" "$extracted"; then
    bootstrap_msg "策略3 zipball：成功"
    echo "$tmp_root/PT-BDtool"
    return 0
  fi

  bootstrap_msg "策略3 zipball 失败：解压后目录无效。"
  return 1
}

bootstrap_fetch_repo() {
  local tmp_root="$1"
  local repo_dir=""

  detect_network || bootstrap_msg "网络检查失败：将继续尝试自举。"

  repo_dir="$(try_git_clone "$tmp_root" || true)"
  if [[ -n "$repo_dir" && -f "$repo_dir/install.sh" && -f "$repo_dir/lib/ui.sh" ]]; then
    echo "$repo_dir"
    return 0
  fi

  repo_dir="$(try_tarball "$tmp_root" || true)"
  if [[ -n "$repo_dir" && -f "$repo_dir/install.sh" && -f "$repo_dir/lib/ui.sh" ]]; then
    echo "$repo_dir"
    return 0
  fi

  repo_dir="$(try_zipball "$tmp_root" || true)"
  if [[ -n "$repo_dir" && -f "$repo_dir/install.sh" && -f "$repo_dir/lib/ui.sh" ]]; then
    echo "$repo_dir"
    return 0
  fi

  return 1
}

if [[ "${PTBD_BOOTSTRAP_DONE:-0}" != "1" && ! -f "$SCRIPT_DIR/lib/ui.sh" ]]; then
  bootstrap_msg "检测到缺少 lib/ui.sh，进入自举模式。"

  tmp_boot="$(mktemp -d -t ptbd-install-XXXXXX)"
  BOOT_DEBUG_LOG="$tmp_boot/bootstrap-debug.log"
  BOOT_TMP_OUT="$tmp_boot/bootstrap-out.tmp"
  BOOT_TMP_ERR="$tmp_boot/bootstrap-err.tmp"
  : > "$BOOT_DEBUG_LOG"

  keep_tmp="${KEEP_TMP:-0}"
  bootstrap_failed=0

  cleanup_boot() {
    if [[ "$keep_tmp" == "1" || "$bootstrap_failed" == "1" ]]; then
      bootstrap_msg "保留临时目录：$tmp_boot"
    else
      rm -rf "$tmp_boot" 2>/dev/null || true
    fi
  }
  trap cleanup_boot EXIT

  repo_dir="$(bootstrap_fetch_repo "$tmp_boot" || true)"
  if [[ -z "$repo_dir" || ! -f "$repo_dir/install.sh" || ! -f "$repo_dir/lib/ui.sh" ]]; then
    bootstrap_failed=1
    bootstrap_msg "自举失败：无法获取完整仓库。"
    bootstrap_msg "调试日志：$BOOT_DEBUG_LOG"
    bootstrap_msg "排查建议："
    bootstrap_msg "1) DNS 失败请检查 /etc/resolv.conf"
    bootstrap_msg "2) TLS/证书失败请安装 ca-certificates"
    bootstrap_msg "3) HTTP 403/404 请检查 URL 或 main 分支"
    bootstrap_msg "4) 超时请检查网络/代理"
    bootstrap_msg "5) 缺少命令请安装 git/curl/wget/tar/unzip"
    bootstrap_msg "离线方案：git clone https://github.com/My15sir/PT-BDtool.git && cd PT-BDtool && bash install.sh"
    exit 1
  fi

  bootstrap_msg "自举完成，切换到仓库目录继续执行：$repo_dir"
  PTBD_BOOTSTRAP_DONE=1 PTBD_BOOTSTRAP_TIMEOUT="$BOOT_TIMEOUT" bash "$repo_dir/install.sh" "${ORIG_ARGS[@]}"
  exit $?
fi

# shellcheck source=lib/ui.sh
source "$SCRIPT_DIR/lib/ui.sh"
# shellcheck source=lib/i18n.sh
source "$SCRIPT_DIR/lib/i18n.sh"

LANG_OVERRIDE=""
NON_INTERACTIVE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --lang)
      [[ $# -ge 2 ]] || break
      LANG_OVERRIDE="$2"
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
    *)
      shift
      ;;
  esac
done

set_lang "$LANG_OVERRIDE"

INSTALL_ROOT=""
APT_UPDATED=0
APT_SUDO_CMD=()
export DEBIAN_FRONTEND=noninteractive

install_target_root() {
  local target_root
  if [[ -w "/opt" || ${EUID:-$(id -u)} -eq 0 ]]; then
    target_root="/opt/PT-BDtool"
  else
    target_root="$HOME/.local/share/pt-bdtool/PT-BDtool-app"
  fi

  mkdir -p "$target_root/lib"
  cp -f "$SCRIPT_DIR/bdtool" "$target_root/bdtool"
  cp -f "$SCRIPT_DIR/install.sh" "$target_root/install.sh"
  cp -f "$SCRIPT_DIR/README.md" "$target_root/README.md" 2>/dev/null || true
  cp -f "$SCRIPT_DIR/lib/ui.sh" "$target_root/lib/ui.sh"
  cp -f "$SCRIPT_DIR/lib/i18n.sh" "$target_root/lib/i18n.sh"
  chmod +x "$target_root/bdtool" "$target_root/install.sh"

  if [[ -w "/usr/local/bin" || ${EUID:-$(id -u)} -eq 0 ]]; then
    ln -sf "$target_root/bdtool" /usr/local/bin/bdtool
  else
    mkdir -p "$HOME/.local/bin"
    ln -sf "$target_root/bdtool" "$HOME/.local/bin/bdtool"
    printf "请确保 ~/.local/bin 在 PATH 中。\n" >&2
  fi

  INSTALL_ROOT="$target_root"
}

setup_apt_privilege() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    APT_SUDO_CMD=()
    return 0
  fi
  if command -v sudo >/dev/null 2>&1; then
    APT_SUDO_CMD=(sudo)
    screen "正在使用 root 执行 apt 操作..."
    return 0
  fi
  return 1
}

is_cmd_installed() {
  command -v "$1" >/dev/null 2>&1
}

is_apt_lock_active() {
  local lock1="/var/lib/dpkg/lock-frontend"
  local lock2="/var/lib/apt/lists/lock"
  local lock3="/var/cache/apt/archives/lock"
  if command -v lsof >/dev/null 2>&1; then
    if lsof "$lock1" "$lock2" "$lock3" >/dev/null 2>&1; then
      return 0
    fi
    return 1
  fi
  if command -v fuser >/dev/null 2>&1; then
    if fuser "$lock1" "$lock2" "$lock3" >/dev/null 2>&1; then
      return 0
    fi
    return 1
  fi
  if pgrep -x apt >/dev/null 2>&1 || pgrep -x apt-get >/dev/null 2>&1 || pgrep -x dpkg >/dev/null 2>&1 || pgrep -f unattended-upgrades >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

show_apt_lock_holder() {
  local lock_file="$1"
  if command -v fuser >/dev/null 2>&1; then
    fuser "$lock_file" 2>/dev/null | sed 's/^/占用进程 PID: /' || true
    return
  fi
  if command -v lsof >/dev/null 2>&1; then
    lsof "$lock_file" 2>/dev/null | tail -n +2 | awk '{print "占用进程 PID: "$2" CMD: "$1}' || true
    return
  fi
  screen "提示：可安装 lsof/fuser 以显示锁占用进程。"
}

collect_apt_lock_pids() {
  local lock1="/var/lib/dpkg/lock-frontend"
  local lock2="/var/lib/apt/lists/lock"
  local lock3="/var/cache/apt/archives/lock"
  local pids=""

  pids+=" $(pgrep -x apt 2>/dev/null || true)"
  pids+=" $(pgrep -x apt-get 2>/dev/null || true)"
  pids+=" $(pgrep -x dpkg 2>/dev/null || true)"
  pids+=" $(pgrep -f unattended-upgrades 2>/dev/null || true)"

  if command -v fuser >/dev/null 2>&1; then
    pids+=" $(fuser "$lock1" "$lock2" "$lock3" 2>/dev/null || true)"
  fi

  echo "$pids" | tr ' ' '\n' | awk '/^[0-9]+$/{print $1}' | sort -u | xargs 2>/dev/null || true
}

kill_pid_force() {
  local pid="$1"
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    kill -TERM "$pid" 2>/dev/null || true
  else
    "${APT_SUDO_CMD[@]}" kill -TERM "$pid" 2>/dev/null || true
  fi
}

kill_pid_hard() {
  local pid="$1"
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    kill -KILL "$pid" 2>/dev/null || true
  else
    "${APT_SUDO_CMD[@]}" kill -KILL "$pid" 2>/dev/null || true
  fi
}

force_recover_apt() {
  local pids pid
  pids="$(collect_apt_lock_pids)"
  if [[ -n "$pids" ]]; then
    screen "检测到 apt/dpkg 占用进程：$pids"
    for pid in $pids; do
      kill_pid_force "$pid"
    done
    sleep 5
    for pid in $pids; do
      if kill -0 "$pid" 2>/dev/null; then
        kill_pid_hard "$pid"
      fi
    done
  fi

  screen "执行 dpkg --configure -a 修复状态..."
  run_ext_boot "$APT_TIMEOUT" "${APT_SUDO_CMD[@]}" dpkg --configure -a >/dev/null 2>&1 || true
}

wait_for_apt_lock() {
  local max_wait="${1:-60}"
  local elapsed=0
  local lock1="/var/lib/dpkg/lock-frontend"
  local lock2="/var/lib/apt/lists/lock"
  local lock3="/var/cache/apt/archives/lock"

  if is_apt_lock_active; then
    screen "检测到 apt/dpkg 占用，尝试强制恢复..."
    [[ -e "$lock1" ]] && show_apt_lock_holder "$lock1"
    [[ -e "$lock2" ]] && show_apt_lock_holder "$lock2"
    [[ -e "$lock3" ]] && show_apt_lock_holder "$lock3"
    force_recover_apt
  fi

  while (( elapsed < max_wait )); do
    if ! is_apt_lock_active; then
      return 0
    fi
    screen "apt/dpkg 仍被占用，继续等待（${elapsed}/${max_wait}s）..."
    sleep 5
    elapsed=$((elapsed + 5))
    if (( elapsed % 10 == 0 )); then
      force_recover_apt
    fi
  done

  screen_error "有其他 apt 进程占用，等待超过 ${max_wait}s。"
  [[ -e "$lock1" ]] && show_apt_lock_holder "$lock1"
  [[ -e "$lock2" ]] && show_apt_lock_holder "$lock2"
  [[ -e "$lock3" ]] && show_apt_lock_holder "$lock3"
  return 1
}

run_timeout_retry() {
  local desc="$1"
  shift
  local attempt rc sleep_s
  local out_file err_file
  out_file="$(mktemp)"
  err_file="$(mktemp)"

  for ((attempt=1; attempt<=APT_RETRY_MAX; attempt++)); do
    run_ext_boot "$APT_TIMEOUT" "$@" >"$out_file" 2>"$err_file" &
    local cmd_pid=$!
    while kill -0 "$cmd_pid" 2>/dev/null; do
      screen "仍在${desc} ..."
      sleep 10
    done

    if wait "$cmd_pid"; then
      rm -f "$out_file" "$err_file"
      return 0
    fi

    rc=$?
    tail -n 20 "$err_file" >&2 || true
    if [[ "$rc" -eq 124 ]]; then
      screen_error "${desc} 超时（>${APT_TIMEOUT}s），第 ${attempt}/${APT_RETRY_MAX} 次失败。"
    else
      screen_error "${desc} 失败（rc=${rc}），第 ${attempt}/${APT_RETRY_MAX} 次失败。"
    fi
    if (( attempt >= APT_RETRY_MAX )); then
      rm -f "$out_file" "$err_file"
      return "$rc"
    fi
    sleep_s=$((2 ** (attempt - 1)))
    sleep "$sleep_s"
  done
  rm -f "$out_file" "$err_file"
  return 1
}

apt_update() {
  if [[ "$APT_UPDATED" -eq 1 ]]; then
    return 0
  fi
  wait_for_apt_lock "$APT_LOCK_WAIT" || return 1
  screen "正在执行 apt-get update（超时 ${APT_TIMEOUT}s）..."
  if [[ "$APT_QUIET" == "1" ]]; then
    run_timeout_retry "执行软件源更新" "${APT_SUDO_CMD[@]}" apt-get -y -qq update || return 1
  else
    run_timeout_retry "执行软件源更新" "${APT_SUDO_CMD[@]}" apt-get -y update || return 1
  fi
  APT_UPDATED=1
  return 0
}

apt_install() {
  local pkgs=("$@")
  wait_for_apt_lock "$APT_LOCK_WAIT" || return 1
  screen "正在安装 ${pkgs[*]}（超时 ${APT_TIMEOUT}s）..."
  if [[ "$APT_QUIET" == "1" ]]; then
    run_timeout_retry "安装 ${pkgs[*]}" "${APT_SUDO_CMD[@]}" apt-get -y -qq install "${pkgs[@]}"
  else
    run_timeout_retry "安装 ${pkgs[*]}" "${APT_SUDO_CMD[@]}" apt-get -y install "${pkgs[@]}"
  fi
}

show_apt_failure_suggestions() {
  screen "建议排查："
  screen "1) 检查网络与软件源可用性。"
  screen "2) 手动验证：apt-get update"
  screen "3) 检查是否有 unattended-upgrades/apt 占用锁。"
}

check_and_install_dep() {
  local dep_cmd="$1"
  local dep_pkg="$2"
  if is_cmd_installed "$dep_cmd"; then
    screen "$dep_cmd $(t DEPEND_OK)"
    return 0
  fi

  screen "检查依赖：$dep_cmd 未安装"
  screen "$dep_cmd $(t DEPEND_INSTALLING)"

  if ! apt_update; then
    screen_error "$dep_cmd 安装前 apt-get update 失败，将直接尝试安装一次。"
  fi

  if ! apt_install "$dep_pkg"; then
    screen_error "$dep_cmd $(t DEPEND_FAIL)"
    show_apt_failure_suggestions
    return 1
  fi

  if is_cmd_installed "$dep_cmd"; then
    screen "$dep_cmd $(t DEPEND_OK)"
    return 0
  fi

  screen_error "$dep_cmd 安装后仍不可用。"
  show_apt_failure_suggestions
  return 1
}

section "PT-BDtool"
failed_dep=0
if ! setup_apt_privilege; then
  screen_error "缺少 root/sudo 权限，无法自动安装依赖。"
  failed_dep=1
fi

check_and_install_dep bash bash || failed_dep=1
check_and_install_dep find findutils || failed_dep=1
check_and_install_dep awk gawk || failed_dep=1
check_and_install_dep sed sed || failed_dep=1
check_and_install_dep sort coreutils || failed_dep=1
check_and_install_dep timeout coreutils || failed_dep=1
check_and_install_dep zip zip || failed_dep=1
check_and_install_dep tar tar || failed_dep=1
check_and_install_dep ffmpeg ffmpeg || true
check_and_install_dep ffprobe ffmpeg || true
check_and_install_dep mediainfo mediainfo || true

if [[ -n "${PTBD_EXTRA_DEPS:-}" ]]; then
  IFS=',' read -r -a _extra_deps <<< "$PTBD_EXTRA_DEPS"
  for dep_item in "${_extra_deps[@]}"; do
    _dep_cmd="${dep_item%%:*}"
    _dep_pkg="${dep_item#*:}"
    [[ -n "$_dep_cmd" && -n "$_dep_pkg" ]] || continue
    check_and_install_dep "$_dep_cmd" "$_dep_pkg" || failed_dep=1
  done
fi

if [[ "$failed_dep" -ne 0 ]]; then
  ensure_output_root
  write_error_file "依赖安装失败" "请检查网络或权限后重试。"
  screen_error "$(t ERR_HINT_FILE)$ERROR_FILE"
fi

install_target_root
screen "安装目录：$INSTALL_ROOT"

if [[ "$NON_INTERACTIVE" -eq 1 || ! -t 0 ]]; then
  exec "$INSTALL_ROOT/bdtool" --non-interactive --lang "$LANG_CODE"
fi

exec "$INSTALL_ROOT/bdtool" --lang "$LANG_CODE"
