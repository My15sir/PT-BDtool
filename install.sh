#!/usr/bin/env bash
set -Eeuo pipefail

ORIG_ARGS=("$@")
SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

bootstrap_log() {
  local root="${PTBD_BOOTSTRAP_LOG_ROOT:-$(pwd)}"
  local log_dir="$root/bdtool-output/logs"
  local log_file="$log_dir/run.log"
  mkdir -p "$log_dir"
  touch "$log_file"
  printf '[%s] [bootstrap] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$log_file" >&2
}

bootstrap_die() {
  bootstrap_log "ERROR: $*"
  bootstrap_log "详情日志：${PTBD_BOOTSTRAP_LOG_ROOT:-$(pwd)}/bdtool-output/logs/run.log"
  exit 1
}

run_timed_bootstrap() {
  local timeout_s="${1:-300}"
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout --preserve-status "${timeout_s}s" "$@"
    return $?
  fi
  "$@" &
  local pid=$!
  local begin now
  begin="$(date +%s)"
  while kill -0 "$pid" 2>/dev/null; do
    now="$(date +%s)"
    if (( now - begin >= timeout_s )); then
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

bootstrap_fetch_repo() {
  local tmp_root="$1"
  local repo_dir="$tmp_root/PT-BDtool"

  if command -v git >/dev/null 2>&1; then
    bootstrap_log "尝试 git clone 仓库..."
    if run_timed_bootstrap 300 git clone --depth 1 --branch main https://github.com/My15sir/PT-BDtool.git "$repo_dir" >/dev/null 2>&1; then
      echo "$repo_dir"
      return 0
    fi
    bootstrap_log "git clone 失败，回退到归档下载。"
  fi

  local tarball="$tmp_root/repo.tar.gz"
  local tar_url="https://codeload.github.com/My15sir/PT-BDtool/tar.gz/refs/heads/main"

  if command -v curl >/dev/null 2>&1; then
    bootstrap_log "尝试 curl 下载仓库归档..."
    run_timed_bootstrap 300 curl -fL --connect-timeout 10 --retry 3 --retry-delay 1 --retry-all-errors -o "$tarball" "$tar_url" >/dev/null 2>&1 || true
  fi

  if [[ ! -s "$tarball" ]] && command -v wget >/dev/null 2>&1; then
    bootstrap_log "尝试 wget 下载仓库归档..."
    run_timed_bootstrap 300 wget -q -O "$tarball" "$tar_url" >/dev/null 2>&1 || true
  fi

  [[ -s "$tarball" ]] || return 1
  command -v tar >/dev/null 2>&1 || bootstrap_die "缺少 tar，无法解压仓库归档"

  run_timed_bootstrap 300 tar -xzf "$tarball" -C "$tmp_root" >/dev/null 2>&1 || return 1
  local extracted
  extracted="$(find "$tmp_root" -maxdepth 1 -type d -name 'PT-BDtool-*' | head -n 1 || true)"
  [[ -n "$extracted" && -d "$extracted" ]] || return 1
  echo "$extracted"
}

if [[ "${PTBD_BOOTSTRAP_DONE:-0}" != "1" && ! -f "$SCRIPT_DIR/lib/ui.sh" ]]; then
  export PTBD_BOOTSTRAP_LOG_ROOT="${PTBD_BOOTSTRAP_LOG_ROOT:-$(pwd)}"
  bootstrap_log "检测到缺少 lib/ui.sh，进入自举模式。"

  tmp_boot="$(mktemp -d -t ptbd-install-XXXXXX)"
  keep_tmp="${KEEP_TMP:-0}"
  cleanup_bootstrap() {
    if [[ "$keep_tmp" == "1" ]]; then
      bootstrap_log "KEEP_TMP=1，保留临时目录：$tmp_boot"
    else
      rm -rf "$tmp_boot" 2>/dev/null || true
    fi
  }
  trap cleanup_bootstrap EXIT

  repo_boot_dir="$(bootstrap_fetch_repo "$tmp_boot" || true)"
  [[ -n "$repo_boot_dir" && -f "$repo_boot_dir/install.sh" && -f "$repo_boot_dir/lib/ui.sh" ]] || bootstrap_die "自举获取完整仓库失败（请检查网络或代理）"

  bootstrap_log "自举完成，切换到仓库目录继续执行：$repo_boot_dir"
  PTBD_BOOTSTRAP_DONE=1 PTBD_BOOTSTRAP_LOG_ROOT="$PTBD_BOOTSTRAP_LOG_ROOT" bash "$repo_boot_dir/install.sh" "${ORIG_ARGS[@]}"
  exit $?
fi

# shellcheck source=lib/ui.sh
source "$SCRIPT_DIR/lib/ui.sh"

BDTOOL_ROOT="$SCRIPT_DIR"
ensure_log_dir "$SCRIPT_DIR"
setup_log_redirection "$SCRIPT_DIR"

trap 'ui_log_error "install ERR cmd=${BASH_COMMAND:-unknown}"; screen_error "安装流程异常"; screen_error "详情见日志：$BDTOOL_RUN_LOG"; exit 1' ERR
trap 'ui_log_error "install interrupted INT"; exit 130' INT
trap 'ui_log_error "install interrupted TERM"; exit 143' TERM

if [[ ! -x "$SCRIPT_DIR/bdtool" ]]; then
  chmod +x "$SCRIPT_DIR/bdtool" 2>/dev/null || true
fi

if [[ $# -eq 0 ]]; then
  if [[ -t 0 && -t 1 ]]; then
    # 安装入口：第一步直接展示 1-7 菜单
    exec "$SCRIPT_DIR/bdtool" --lang zh
  fi
  exec "$SCRIPT_DIR/bdtool" install --non-interactive --lang zh
fi

case "$1" in
  --non-interactive)
    shift
    exec "$SCRIPT_DIR/bdtool" install --non-interactive --lang zh "$@"
    ;;
  install|doctor|scan|clean|logs|tasks|help|--help|-h)
    exec "$SCRIPT_DIR/bdtool" "$@"
    ;;
  *)
    # 兼容旧用法：未知参数默认走安装
    exec "$SCRIPT_DIR/bdtool" install "$@"
    ;;
esac
