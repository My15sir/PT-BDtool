#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BDTOOL_ROOT="$SCRIPT_DIR"
if [[ -f "$SCRIPT_DIR/lib/ui.sh" ]]; then
  # shellcheck source=lib/ui.sh
  source "$SCRIPT_DIR/lib/ui.sh"
else
  log_info() { printf "[INFO] %s\n" "$*" >&2; }
  log_warn() { printf "[WARN] %s\n" "$*" >&2; }
  log_err() { printf "[ERROR] %s\n" "$*" >&2; }
  log_success() { printf "[SUCCESS] %s\n" "$*" >&2; }
  hr() { printf "================================================================\n" >&2; }
  section() { hr; printf "%s\n" "$*" >&2; hr; }
  prompt_with_default() { local p="${1:-请输入值}" d="${2:-}" v=""; read -r -p "  ▶ ${p} [默认 ${d}]: " v < /dev/tty || true; printf "%s" "${v:-$d}"; }
  validate_nonempty() { [[ -n "${1:-}" ]]; }
  validate_int_range() { local v="${1:-}" min="${2:-1}" max="${3:-65535}"; [[ "$v" =~ ^[0-9]+$ ]] && (( v >= min && v <= max )); }
  ensure_log_dir() { local root="${1:-$SCRIPT_DIR}"; BDTOOL_ROOT="$root"; BDTOOL_LOG_DIR="$root/bdtool-output/logs"; BDTOOL_RUN_LOG="$BDTOOL_LOG_DIR/run.log"; mkdir -p "$BDTOOL_LOG_DIR"; touch "$BDTOOL_RUN_LOG"; }
  setup_log_redirection() { ensure_log_dir "${1:-$SCRIPT_DIR}"; [[ "${BDTOOL_LOG_REDIRECTED:-0}" == "1" ]] && return 0; BDTOOL_LOG_REDIRECTED=1; exec > >(tee -a "$BDTOOL_RUN_LOG") 2> >(tee -a "$BDTOOL_RUN_LOG" >&2); }
  execute_with_spinner() { local m="$1"; shift; ensure_log_dir "${BDTOOL_ROOT:-$SCRIPT_DIR}"; "$@" >> "$BDTOOL_RUN_LOG" 2>&1; local r=$?; [[ "$r" -eq 0 ]] && log_success "$m 完成" || log_err "$m 失败 (请查看 $BDTOOL_RUN_LOG)"; return "$r"; }
  die() { local m="${1:-执行失败}" c="${2:-1}"; ensure_log_dir "${BDTOOL_ROOT:-$SCRIPT_DIR}"; log_err "$m"; log_err "详情日志：$BDTOOL_RUN_LOG"; exit "$c"; }
fi
ensure_log_dir "$SCRIPT_DIR"
setup_log_redirection "$SCRIPT_DIR"

# PT-BDtool installer
# 用法：
#   bash <(curl -fsSL https://raw.githubusercontent.com/My15sir/PT-BDtool/main/install.sh) [-k] [--lang zh|en]
# 选项：
#   -k  自动安装依赖：ffmpeg / mediainfo / docker（以及基础工具）
#   --lang zh|en  指定安装提示语言（默认自动检测）

DO_K="0"
ARG_LANG=""
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

prompt_lang() {
  local def ans norm
  def="$(detect_default_lang)"
  if [[ "$def" == "zh" ]]; then
    section "请选择语言 / Select language"
    ans="$(prompt_with_default "输入 1(中文) 或 2(English)" "1")"
  else
    section "Select language / 请选择语言"
    ans="$(prompt_with_default "Input 1(中文) or 2(English)" "2")"
  fi

  if [[ -z "${ans:-}" ]]; then
    echo "$def"
    return 0
  fi

  case "$ans" in
    1) echo "zh" ;;
    2) echo "en" ;;
    *)
      norm="$(normalize_lang "$ans" 2>/dev/null || true)"
      [[ -n "$norm" ]] && echo "$norm" || echo "$def"
      ;;
  esac
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

  if [[ -t 0 ]]; then
    log_info "Waiting for language selection... / 正在等待选择语言..."
    prompt_lang
  else
    detect_default_lang
  fi
}

BD_LANG="$(detect_lang)"

msg() {
  local key="$1"
  shift || true
  local text=""
  case "$key" in
    start) [[ "$BD_LANG" == "zh" ]] && text="开始（k=%s）" || text="start (k=%s)" ;;
    install_deps) [[ "$BD_LANG" == "zh" ]] && text="安装依赖：ffmpeg / mediainfo / docker" || text="install deps: ffmpeg / mediainfo / docker" ;;
    bdinfo_install_start) [[ "$BD_LANG" == "zh" ]] && text="安装 BDInfoCLI-ng（Linux x64 预编译包）" || text="install BDInfoCLI-ng (Linux x64 prebuilt)" ;;
    bdinfo_skip_os) [[ "$BD_LANG" == "zh" ]] && text="跳过 BDInfoCLI-ng 自动安装：仅支持 Linux x64" || text="skip BDInfoCLI-ng auto install: only Linux x64 is supported" ;;
    bdinfo_skip_arch) [[ "$BD_LANG" == "zh" ]] && text="跳过 BDInfoCLI-ng 自动安装：不支持的架构 %s（需要 x64）" || text="skip BDInfoCLI-ng auto install: unsupported arch %s (need x64)" ;;
    path_temp_added) [[ "$BD_LANG" == "zh" ]] && text="提示：已临时加入 PATH。建议执行：source ~/.bashrc 或重新打开终端。" || text="Hint: PATH was updated for current shell. Run: source ~/.bashrc or reopen terminal." ;;
    installed_path) [[ "$BD_LANG" == "zh" ]] && text="已安装：%s/bdtool" || text="installed: %s/bdtool" ;;
    done) [[ "$BD_LANG" == "zh" ]] && text="完成" || text="done" ;;
    next_title) [[ "$BD_LANG" == "zh" ]] && text="下一步（可复制执行）：" || text="Next steps (copy & run):" ;;
    next_1) [[ "$BD_LANG" == "zh" ]] && text="  检查依赖：bdtool doctor" || text="  Check deps: bdtool doctor" ;;
    next_2) [[ "$BD_LANG" == "zh" ]] && text="  开始扫描：bdtool <path>" || text="  Start scan: bdtool <path>" ;;
    next_3) [[ "$BD_LANG" == "zh" ]] && text="  清理输出：bdtool clean" || text="  Clean output: bdtool clean" ;;
    fail) [[ "$BD_LANG" == "zh" ]] && text="安装失败（请查看上方错误信息）" || text="installation failed (see error above)" ;;
    *) text="$key" ;;
  esac

  if [[ "$#" -gt 0 ]]; then
    # shellcheck disable=SC2059
    log_info "$(printf "$text" "$@")"
  else
    log_info "$text"
  fi
}

need_cmd() { command -v "$1" >/dev/null 2>&1; }
is_root() { [[ "${EUID:-$(id -u)}" -eq 0 ]]; }

on_err() { msg fail; }
trap on_err ERR

sudo_cmd() {
  if is_root; then
    echo ""
  else
    need_cmd sudo || die "需要 root 权限或 sudo（当前不是 root 且未安装 sudo）"
    echo "sudo"
  fi
}

dl() {
  local url="$1"
  if need_cmd wget; then
    wget -qO- "$url"
  elif need_cmd curl; then
    curl -fsSL "$url"
  else
    die "需要 wget 或 curl（请先安装其一）"
  fi
}

dl_to_file() {
  local url="$1"
  local output="$2"
  dl "$url" > "$output"
}

install_bdinfo_cli() {
  local install_dir="$1"
  local os arch
  os="$(uname -s 2>/dev/null || true)"
  arch="$(uname -m 2>/dev/null || true)"

  if [[ "$os" != "Linux" ]]; then
    msg bdinfo_skip_os
    return 0
  fi

  case "$arch" in
    x86_64|amd64) ;;
    *)
      msg bdinfo_skip_arch "$arch"
      return 0
      ;;
  esac

  local url
  url="https://github.com/tetrahydroc/BDInfoCLI/releases/latest/download/BDInfo-linux-x64.tar.gz"
  local tmpd tarball bdinfo_bin
  tmpd="$(mktemp -d)"
  tarball="$tmpd/BDInfo-linux-x64.tar.gz"

  msg bdinfo_install_start
  execute_with_spinner "下载 BDInfoCLI-ng" dl_to_file "$url" "$tarball" || { rm -rf "$tmpd"; die "BDInfoCLI-ng 下载失败"; }
  execute_with_spinner "解压 BDInfoCLI-ng" tar -xzf "$tarball" -C "$tmpd" || { rm -rf "$tmpd"; die "BDInfoCLI-ng 解压失败"; }

  bdinfo_bin="$(find "$tmpd" -type f -name BDInfo | head -n 1 || true)"
  [[ -n "$bdinfo_bin" && -f "$bdinfo_bin" ]] || { rm -rf "$tmpd"; die "BDInfoCLI-ng 安装失败：未找到 BDInfo 可执行文件"; }

  if need_cmd install; then
    execute_with_spinner "安装 BDInfo 到 $install_dir" install -m 0755 "$bdinfo_bin" "$install_dir/BDInfo" || { rm -rf "$tmpd"; die "安装 BDInfo 失败"; }
  else
    execute_with_spinner "安装 BDInfo 到 $install_dir" cp "$bdinfo_bin" "$install_dir/BDInfo" || { rm -rf "$tmpd"; die "安装 BDInfo 失败"; }
    chmod +x "$install_dir/BDInfo"
  fi
  rm -rf "$tmpd"
}

start_docker_best_effort() {
  local SUDO
  SUDO="$(sudo_cmd)"
  if need_cmd systemctl; then
    $SUDO systemctl enable --now docker >/dev/null 2>&1 || true
  elif need_cmd service; then
    $SUDO service docker start >/dev/null 2>&1 || true
  fi
}

install_deps() {
  local SUDO
  SUDO="$(sudo_cmd)"

  if need_cmd apt-get; then
    execute_with_spinner "apt 更新索引" $SUDO apt-get update -y || die "apt-get update 失败"
    execute_with_spinner "apt 安装依赖" $SUDO apt-get install -y ca-certificates curl wget git ffmpeg mediainfo docker.io || die "apt-get install 失败"
    start_docker_best_effort
    return 0
  fi

  if need_cmd dnf; then
    execute_with_spinner "dnf 更新缓存" $SUDO dnf makecache -y || true
    execute_with_spinner "dnf 安装依赖" $SUDO dnf install -y ca-certificates curl wget git ffmpeg mediainfo docker || true
    start_docker_best_effort
    return 0
  fi

  if need_cmd yum; then
    execute_with_spinner "yum 更新缓存" $SUDO yum makecache -y || true
    execute_with_spinner "yum 安装依赖" $SUDO yum install -y ca-certificates curl wget git ffmpeg mediainfo docker || true
    start_docker_best_effort
    return 0
  fi

  if need_cmd apk; then
    execute_with_spinner "apk 安装依赖" $SUDO apk add --no-cache ca-certificates curl wget git ffmpeg mediainfo docker || die "apk add 失败"
    $SUDO rc-update add docker default >/dev/null 2>&1 || true
    $SUDO service docker start >/dev/null 2>&1 || true
    return 0
  fi

  if need_cmd pacman; then
    execute_with_spinner "pacman 安装依赖" $SUDO pacman -Sy --noconfirm ca-certificates curl wget git ffmpeg mediainfo docker || die "pacman 安装失败"
    start_docker_best_effort
    return 0
  fi

  die "未识别到包管理器（apt/dnf/yum/apk/pacman），无法自动安装依赖"
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

  die "无法确定 HOME，无法安装"
}

ensure_path_for_user_dir() {
  local dir="$1"

  case "$dir" in
    /usr/local/bin|/usr/bin|/bin|/usr/sbin|/sbin) return 0 ;;
  esac

  if ! echo ":$PATH:" | grep -q ":$dir:"; then
    if [[ -f "$HOME/.bashrc" ]]; then
      if ! grep -qF "export PATH=\"$dir:\$PATH\"" "$HOME/.bashrc"; then
        echo "export PATH=\"$dir:\$PATH\"" >> "$HOME/.bashrc"
      fi
    fi
    export PATH="$dir:$PATH"
    msg path_temp_added
  fi
}

section "PT-BDtool 安装"
msg start "$DO_K"

if [[ "$DO_K" == "1" ]]; then
  msg install_deps
  install_deps
fi

BDTOOL_RAW_URL="https://raw.githubusercontent.com/My15sir/PT-BDtool/main/bdtool.sh"
INSTALL_DIR="$(choose_install_dir)"
mkdir -p "$INSTALL_DIR"

execute_with_spinner "下载 bdtool" dl_to_file "$BDTOOL_RAW_URL" "$INSTALL_DIR/bdtool" || die "下载 bdtool 失败"
chmod +x "$INSTALL_DIR/bdtool"

ensure_path_for_user_dir "$INSTALL_DIR"
install_bdinfo_cli "$INSTALL_DIR"

need_cmd BDInfo || die "安装后未检测到 BDInfo，请确认 PATH 包含 $INSTALL_DIR"

msg installed_path "$INSTALL_DIR"
"$INSTALL_DIR/bdtool" --help >/dev/null 2>&1 || true
msg done
msg next_title
msg next_1
msg next_2
msg next_3
