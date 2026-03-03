#!/usr/bin/env bash
set -Euo pipefail

ORIG_ARGS=("$@")
SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

BOOT_TIMEOUT="${PTBD_BOOTSTRAP_TIMEOUT:-300}"
BOOT_RETRY_MAX="${PTBD_BOOTSTRAP_RETRY:-3}"
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

pkg_manager_install() {
  local pkg="$1"
  local updated="${2:-0}"

  if command -v apt-get >/dev/null 2>&1; then
    local sudo_cmd=()
    if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
      if command -v sudo >/dev/null 2>&1; then
        sudo_cmd=(sudo)
      else
        return 1
      fi
    fi

    if [[ ${#sudo_cmd[@]} -gt 0 ]]; then
      screen "正在使用 root 安装依赖..."
    fi

    if [[ "$updated" == "0" ]]; then
      run_ext_boot 300 "${sudo_cmd[@]}" apt-get update >/dev/null 2>&1 || return 2
    fi

    run_ext_boot 300 "${sudo_cmd[@]}" apt-get install -y "$pkg" >/dev/null 2>&1 || return 3
    return 0
  fi

  return 4
}

check_and_install_dep() {
  local dep_cmd="$1"
  local dep_pkg="$2"
  local -n updated_ref=$3

  if command -v "$dep_cmd" >/dev/null 2>&1; then
    screen "$dep_cmd $(t DEPEND_OK)"
    return 0
  fi

  screen "$dep_cmd $(t DEPEND_INSTALLING)"
  if pkg_manager_install "$dep_pkg" "$updated_ref"; then
    updated_ref=1
    if command -v "$dep_cmd" >/dev/null 2>&1; then
      screen "$dep_cmd $(t DEPEND_OK)"
      return 0
    fi
  fi

  screen_error "$dep_cmd $(t DEPEND_FAIL)"
  return 1
}

section "PT-BDtool"
updated_once=0
failed_dep=0

check_and_install_dep bash bash updated_once || failed_dep=1
check_and_install_dep find findutils updated_once || failed_dep=1
check_and_install_dep awk gawk updated_once || failed_dep=1
check_and_install_dep sed sed updated_once || failed_dep=1
check_and_install_dep sort coreutils updated_once || failed_dep=1
check_and_install_dep timeout coreutils updated_once || failed_dep=1
check_and_install_dep zip zip updated_once || failed_dep=1
check_and_install_dep tar tar updated_once || failed_dep=1
check_and_install_dep ffmpeg ffmpeg updated_once || true
check_and_install_dep ffprobe ffmpeg updated_once || true
check_and_install_dep mediainfo mediainfo updated_once || true

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
