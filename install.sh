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

  bootstrap_log "自举完成，切换到仓库目录继续安装：$repo_boot_dir"
  PTBD_BOOTSTRAP_DONE=1 PTBD_BOOTSTRAP_LOG_ROOT="$PTBD_BOOTSTRAP_LOG_ROOT" bash "$repo_boot_dir/install.sh" "${ORIG_ARGS[@]}"
  exit $?
fi

BDTOOL_ROOT="$SCRIPT_DIR"
# shellcheck source=lib/ui.sh
source "$SCRIPT_DIR/lib/ui.sh"

LOG_ROOT="${PTBD_BOOTSTRAP_LOG_ROOT:-$SCRIPT_DIR}"
ensure_log_dir "$LOG_ROOT"
setup_log_redirection "$LOG_ROOT"

trap 'error "发生未捕捉错误，详情见日志"; error "详情日志：$BDTOOL_RUN_LOG"; if [[ "${SHOW_ERR_TAIL:-1}" == "1" ]]; then echo; tail -n 50 "$BDTOOL_RUN_LOG" 2>/dev/null || true; fi' ERR

: "${BDTOOL_NO_PROMPT:=1}"
: "${BDTOOL_CMD_TIMEOUT:=300}"
: "${BDTOOL_FETCH_TIMEOUT:=45}"
: "${BDTOOL_FETCH_RETRIES:=3}"
: "${BDTOOL_HTTP_PROXY:=}"
: "${DEMO:=0}"

DO_K="0"
ARG_LANG=""
DRY_RUN="0"
NON_INTERACTIVE="0"
INSTALL_PASSWORD="${BDTOOL_INSTALL_PASSWORD:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -k) DO_K="1"; shift ;;
    --lang)
      [[ $# -ge 2 ]] || die "--lang requires a value: zh|en"
      ARG_LANG="$2"
      shift 2
      ;;
    --lang=*)
      ARG_LANG="${1#*=}"
      shift
      ;;
    --dry-run)
      DRY_RUN="1"
      shift
      ;;
    --non-interactive)
      NON_INTERACTIVE="1"
      BDTOOL_NO_PROMPT=1
      shift
      ;;
    --password)
      [[ $# -ge 2 ]] || die "--password requires a value"
      INSTALL_PASSWORD="$2"
      shift 2
      ;;
    --password=*)
      INSTALL_PASSWORD="${1#*=}"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

normalize_lang() {
  local v
  v="$(echo "${1:-}" | tr '[:upper:]' '[:lower:]')"
  case "$v" in
    zh|zh_cn|cn|chinese) echo "zh" ;;
    en|en_us|english) echo "en" ;;
    *) return 1 ;;
  esac
}

detect_default_lang() {
  local locale
  locale="${LC_ALL:-${LANG:-}}"
  if [[ "$locale" == *zh* || "$locale" == *ZH* ]]; then
    echo "zh"
  else
    echo "en"
  fi
}

detect_lang() {
  local norm
  if [[ -n "$ARG_LANG" ]]; then
    norm="$(normalize_lang "$ARG_LANG" 2>/dev/null || true)"
    [[ -n "$norm" ]] || die "invalid --lang: $ARG_LANG (use zh|en)"
    echo "$norm"
    return 0
  fi

  if [[ -n "${BDTOOL_LANG:-}" ]]; then
    norm="$(normalize_lang "$BDTOOL_LANG" 2>/dev/null || true)"
    [[ -n "$norm" ]] || die "invalid BDTOOL_LANG: $BDTOOL_LANG (use zh|en)"
    echo "$norm"
    return 0
  fi

  detect_default_lang
}

BD_LANG="$(detect_lang)"

msg() {
  local zh="$1"
  local en="$2"
  if [[ "$BD_LANG" == "zh" ]]; then
    info "$zh"
  else
    info "$en"
  fi
}

need_cmd() { command -v "$1" >/dev/null 2>&1; }
is_root() { [[ "${EUID:-$(id -u)}" -eq 0 ]]; }

sudo_cmd() {
  if is_root; then
    echo ""
    return 0
  fi
  if need_cmd sudo; then
    echo "sudo"
    return 0
  fi
  return 1
}

proxy_env_prefix() {
  local p="${BDTOOL_HTTP_PROXY:-${HTTPS_PROXY:-${https_proxy:-${HTTP_PROXY:-${http_proxy:-}}}}}"
  if [[ -n "$p" ]]; then
    printf 'HTTP_PROXY=%q HTTPS_PROXY=%q http_proxy=%q https_proxy=%q NO_PROXY=%q no_proxy=%q' \
      "$p" "$p" "$p" "$p" "${NO_PROXY:-${no_proxy:-}}" "${no_proxy:-${NO_PROXY:-}}"
  else
    printf ''
  fi
}

curl_fetch() {
  local url="$1"
  local output="$2"
  local px
  px="$(proxy_env_prefix)"

  if [[ -n "$px" ]]; then
    eval "$px" timeout "${BDTOOL_FETCH_TIMEOUT}s" curl -fL --connect-timeout 10 --retry 2 --retry-delay 1 --retry-all-errors -o "\"$output\"" "\"$url\""
  else
    timeout "${BDTOOL_FETCH_TIMEOUT}s" curl -fL --connect-timeout 10 --retry 2 --retry-delay 1 --retry-all-errors -o "$output" "$url"
  fi
}

wget_fetch() {
  local url="$1"
  local output="$2"
  local px
  px="$(proxy_env_prefix)"

  if [[ -n "$px" ]]; then
    eval "$px" timeout "${BDTOOL_FETCH_TIMEOUT}s" wget -q --timeout=20 --tries=2 -O "\"$output\"" "\"$url\""
  else
    timeout "${BDTOOL_FETCH_TIMEOUT}s" wget -q --timeout=20 --tries=2 -O "$output" "$url"
  fi
}

fetch_with_fallbacks() {
  local output="$1"
  shift
  local urls=("$@")

  [[ "${#urls[@]}" -gt 0 ]] || return 1
  rm -f "$output"

  local u i
  for u in "${urls[@]}"; do
    i=1
    while [[ "$i" -le "$BDTOOL_FETCH_RETRIES" ]]; do
      if need_cmd curl && curl_fetch "$u" "$output"; then
        [[ -s "$output" ]] && return 0
      fi
      if need_cmd wget && wget_fetch "$u" "$output"; then
        [[ -s "$output" ]] && return 0
      fi
      i=$((i + 1))
    done
  done

  rm -f "$output"
  return 1
}

install_deps() {
  local sudo_prefix=""
  if ! sudo_prefix="$(sudo_cmd)"; then
    msg "当前非 root 且无 sudo，跳过依赖安装。" "Not root and sudo is unavailable, skip dependency install."
    return 0
  fi

  if need_cmd apt-get; then
    execute_with_spinner "apt update" $sudo_prefix apt-get update -y || return 1
    execute_with_spinner "apt install deps" $sudo_prefix apt-get install -y ca-certificates curl wget git ffmpeg mediainfo docker.io || return 1
    return 0
  fi

  if need_cmd dnf; then
    execute_with_spinner "dnf makecache" $sudo_prefix dnf makecache -y || true
    execute_with_spinner "dnf install deps" $sudo_prefix dnf install -y ca-certificates curl wget git ffmpeg mediainfo docker || true
    return 0
  fi

  if need_cmd yum; then
    execute_with_spinner "yum makecache" $sudo_prefix yum makecache -y || true
    execute_with_spinner "yum install deps" $sudo_prefix yum install -y ca-certificates curl wget git ffmpeg mediainfo docker || true
    return 0
  fi

  if need_cmd apk; then
    execute_with_spinner "apk install deps" $sudo_prefix apk add --no-cache ca-certificates curl wget git ffmpeg mediainfo docker || return 1
    return 0
  fi

  if need_cmd pacman; then
    execute_with_spinner "pacman install deps" $sudo_prefix pacman -Sy --noconfirm ca-certificates curl wget git ffmpeg mediainfo docker || return 1
    return 0
  fi

  msg "未识别包管理器，跳过自动装依赖。" "Unknown package manager, skip auto dependency install."
  return 0
}

choose_install_dir() {
  if is_root; then
    if [[ -d "/usr/local/bin" && -w "/usr/local/bin" ]]; then
      echo "/usr/local/bin"
      return 0
    fi
    echo "$HOME/bin"
    return 0
  fi

  if [[ -n "${HOME:-}" ]]; then
    if [[ -d "$HOME/.local/bin" || ! -e "$HOME/.local/bin" ]]; then
      echo "$HOME/.local/bin"
      return 0
    fi
    echo "$HOME/bin"
    return 0
  fi

  die "cannot determine install dir"
}

ensure_path_for_user_dir() {
  local dir="$1"
  case "$dir" in
    /usr/local/bin|/usr/bin|/bin|/usr/sbin|/sbin) return 0 ;;
  esac

  if ! echo ":$PATH:" | grep -q ":$dir:"; then
    if [[ -f "$HOME/.bashrc" ]] && ! grep -qF "export PATH=\"$dir:\$PATH\"" "$HOME/.bashrc"; then
      echo "export PATH=\"$dir:\$PATH\"" >> "$HOME/.bashrc"
    fi
    export PATH="$dir:$PATH"
    msg "已临时加入 PATH：$dir" "Temporarily added to PATH: $dir"
  fi
}

download_repo_file() {
  local rel="$1"
  local out="$2"

  if [[ -f "$SCRIPT_DIR/$rel" ]]; then
    cp -f "$SCRIPT_DIR/$rel" "$out"
    [[ -s "$out" ]] && return 0
  fi

  local urls=(
    "https://raw.githubusercontent.com/My15sir/PT-BDtool/main/$rel"
    "https://cdn.jsdelivr.net/gh/My15sir/PT-BDtool@main/$rel"
  )
  fetch_with_fallbacks "$out" "${urls[@]}"
}

install_cli_bundle() {
  local install_dir="$1"
  local tmpd
  tmpd="$(mktemp -d)"
  mkdir -p "$install_dir/lib"

  download_repo_file "bdtool" "$tmpd/bdtool" || { rm -rf "$tmpd"; return 1; }
  download_repo_file "bdtool.sh" "$tmpd/bdtool.sh" || { rm -rf "$tmpd"; return 1; }
  download_repo_file "install.sh" "$tmpd/install.sh" || { rm -rf "$tmpd"; return 1; }
  download_repo_file "lib/ui.sh" "$tmpd/ui.sh" || { rm -rf "$tmpd"; return 1; }
  download_repo_file "lib/i18n.sh" "$tmpd/i18n.sh" || { rm -rf "$tmpd"; return 1; }

  install -m 0755 "$tmpd/bdtool" "$install_dir/bdtool"
  install -m 0755 "$tmpd/bdtool.sh" "$install_dir/bdtool.sh"
  install -m 0755 "$tmpd/install.sh" "$install_dir/install.sh"
  install -m 0644 "$tmpd/ui.sh" "$install_dir/lib/ui.sh"
  install -m 0644 "$tmpd/i18n.sh" "$install_dir/lib/i18n.sh"

  rm -rf "$tmpd"
  return 0
}

install_bdinfo_cli() {
  local install_dir="$1"
  local os arch
  os="$(uname -s 2>/dev/null || true)"
  arch="$(uname -m 2>/dev/null || true)"

  if [[ "$os" != "Linux" ]]; then
    msg "跳过 BDInfo 自动安装：仅支持 Linux x64。" "Skip BDInfo auto-install: only Linux x64 is supported."
    return 0
  fi

  case "$arch" in
    x86_64|amd64) ;;
    *)
      msg "跳过 BDInfo 自动安装：架构不支持（$arch）。" "Skip BDInfo auto-install: unsupported arch ($arch)."
      return 0
      ;;
  esac

  local tmpd tarball bdinfo_bin
  tmpd="$(mktemp -d)"
  tarball="$tmpd/BDInfo-linux-x64.tar.gz"

  local urls=(
    "https://github.com/tetrahydroc/BDInfoCLI/releases/latest/download/BDInfo-linux-x64.tar.gz"
    "https://ghproxy.com/https://github.com/tetrahydroc/BDInfoCLI/releases/latest/download/BDInfo-linux-x64.tar.gz"
  )

  info "下载 BDInfoCLI-ng..."
  fetch_with_fallbacks "$tarball" "${urls[@]}" || { rm -rf "$tmpd"; return 1; }
  execute_with_spinner "解压 BDInfoCLI-ng" tar -xzf "$tarball" -C "$tmpd" || { rm -rf "$tmpd"; return 1; }
  bdinfo_bin="$(find "$tmpd" -type f -name BDInfo | head -n 1 || true)"
  [[ -n "$bdinfo_bin" && -f "$bdinfo_bin" ]] || { rm -rf "$tmpd"; return 1; }

  if need_cmd install; then
    execute_with_spinner "安装 BDInfo" install -m 0755 "$bdinfo_bin" "$install_dir/BDInfo" || { rm -rf "$tmpd"; return 1; }
  else
    execute_with_spinner "安装 BDInfo" cp "$bdinfo_bin" "$install_dir/BDInfo" || { rm -rf "$tmpd"; return 1; }
    chmod +x "$install_dir/BDInfo"
  fi
  rm -rf "$tmpd"
  return 0
}

validate_password_len_12() {
  [[ ${#1} -ge 12 ]]
}

collect_install_password() {
  if [[ -n "$INSTALL_PASSWORD" ]]; then
    if validate_password_len_12 "$INSTALL_PASSWORD"; then
      success "密码校验通过。"
      return 0
    fi
    error "安全性不足：密码长度必须 ≥ 12 位！"
    hint "请通过 --password 或 BDTOOL_INSTALL_PASSWORD 传入 12 位以上密码。"
    die "安装参数校验失败。"
  fi

  if [[ "$DEMO" == "1" ]]; then
    info "DEMO=1：将自动演示一次短密码失败并重试成功。"
    export PROMPT_INPUTS_INSTALL_PASSWORD="${PROMPT_INPUTS_INSTALL_PASSWORD:-short123,VeryStrongPassword123!}"
    prompt_secret_with_rules INSTALL_PASSWORD "请输入管理密码（必须 >= 12 位）" 12 3 0
    success "DEMO：密码重试流程验证通过。"
    return 0
  fi

  prompt_secret_with_rules INSTALL_PASSWORD "请输入管理密码（可留空跳过）" 12 3 1
  if [[ -n "$INSTALL_PASSWORD" ]]; then
    success "密码校验通过。"
  else
    info "未设置管理密码，继续执行安装。"
  fi
}

section "PT-BDtool install"
msg "安装开始" "Install started"

collect_install_password

if [[ "$DRY_RUN" == "1" ]]; then
  msg "当前为 dry-run，仅做环境检测，不执行下载/安装。" "Dry-run mode, only checks environment without downloading/installing."
  for c in bash ffmpeg ffprobe mediainfo BDInfo curl wget git tar unzip; do
    if need_cmd "$c"; then
      success "found: $c"
    else
      warn "missing: $c"
    fi
  done
  exit 0
fi

if [[ "$DO_K" == "1" ]]; then
  install_deps || die "dependency install failed"
fi

INSTALL_DIR="$(choose_install_dir)"
mkdir -p "$INSTALL_DIR"

info "安装 CLI 入口与运行所需脚本..."
install_cli_bundle "$INSTALL_DIR" || die "failed to install cli bundle (check network/proxy and $BDTOOL_RUN_LOG)"

ensure_path_for_user_dir "$INSTALL_DIR"
hash -r 2>/dev/null || true

if ! command -v bdtool >/dev/null 2>&1; then
  hint "若未生效，请重新打开终端或手动执行：export PATH=\"$INSTALL_DIR:\$PATH\""
  die "bdtool command is not found after install"
fi
success "bdtool command ready: $(command -v bdtool)"

if ! need_cmd BDInfo; then
  install_bdinfo_cli "$INSTALL_DIR" || warn "BDInfo install failed, continue"
fi

if need_cmd BDInfo; then
  success "BDInfo is available"
else
  warn "BDInfo is missing, please configure PATH or install manually"
fi

msg "安装完成" "Install completed"
msg "下一步：bdtool doctor" "Next: bdtool doctor"

auto_launch_menu_after_install() {
  local auto_launch="${AUTO_LAUNCH_MENU:-1}"
  [[ "$auto_launch" == "1" ]] || return 0
  [[ "$DRY_RUN" == "0" ]] || return 0
  [[ "$NON_INTERACTIVE" == "0" ]] || return 0
  if [[ ! -t 0 ]]; then
    msg "检测到非交互终端，跳过自动菜单。" "Non-interactive terminal detected, skip auto menu launch."
    return 0
  fi

  local menu_entry=""
  if command -v bdtool >/dev/null 2>&1; then
    menu_entry="$(command -v bdtool)"
  elif [[ -x "$SCRIPT_DIR/bdtool" ]]; then
    menu_entry="$SCRIPT_DIR/bdtool"
  elif [[ -x "$SCRIPT_DIR/ptbd" ]]; then
    menu_entry="$SCRIPT_DIR/ptbd"
  else
    warn "cannot find menu entry (bdtool/ptbd), skip auto menu launch"
    return 0
  fi

  msg "自动进入菜单界面..." "Launching interactive menu..."
  BDTOOL_NO_PROMPT=0 "$menu_entry" --lang "$BD_LANG" || warn "menu exited with non-zero status"
}

auto_launch_menu_after_install
