#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BDTOOL_ROOT="$SCRIPT_DIR"
if [[ -f "$SCRIPT_DIR/lib/ui.sh" ]]; then
  # shellcheck source=lib/ui.sh
  source "$SCRIPT_DIR/lib/ui.sh"
else
  echo "[ERROR] missing lib/ui.sh" >&2
  exit 1
fi
ensure_log_dir "$SCRIPT_DIR"
setup_log_redirection "$SCRIPT_DIR"

DO_K="0"
ARG_LANG=""
DRY_RUN="0"

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

  if [[ "${BDTOOL_NO_PROMPT:-1}" == "1" ]]; then
    detect_default_lang
    return 0
  fi

  if [[ -t 0 ]]; then
    log_info "Waiting for language selection... / 正在等待选择语言..."
    local def ans
    def="$(detect_default_lang)"
    if [[ "$def" == "zh" ]]; then
      ans="$(prompt_with_default "输入 1(中文) 或 2(English)" "1")"
    else
      ans="$(prompt_with_default "Input 1(中文) or 2(English)" "2")"
    fi
    case "$ans" in
      1) echo "zh" ;;
      2) echo "en" ;;
      *) detect_default_lang ;;
    esac
  else
    detect_default_lang
  fi
}

BD_LANG="$(detect_lang)"

msg() {
  local zh="$1"
  local en="$2"
  if [[ "$BD_LANG" == "zh" ]]; then
    log_info "$zh"
  else
    log_info "$en"
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

dl_to_file() {
  local url="$1"
  local output="$2"
  if need_cmd wget; then
    wget -qO "$output" "$url"
  elif need_cmd curl; then
    curl -fsSL "$url" -o "$output"
  else
    return 127
  fi
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

install_bdinfo_cli() {
  local install_dir="$1"
  local os arch
  os="$(uname -s 2>/dev/null || true)"
  arch="$(uname -m 2>/dev/null || true)"
  local url="https://github.com/tetrahydroc/BDInfoCLI/releases/latest/download/BDInfo-linux-x64.tar.gz"

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

  execute_with_spinner "下载 BDInfoCLI-ng" dl_to_file "$url" "$tarball" || { rm -rf "$tmpd"; return 1; }
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

section "PT-BDtool install"
msg "安装开始" "Install started"

if [[ "$DRY_RUN" == "1" ]]; then
  msg "当前为 dry-run，仅做环境检测，不执行下载/安装。" "Dry-run mode, only checks environment without downloading/installing."
  for c in bash ffmpeg ffprobe mediainfo BDInfo; do
    if need_cmd "$c"; then
      log_success "found: $c"
    else
      log_warn "missing: $c"
    fi
  done
  exit 0
fi

if [[ "$DO_K" == "1" ]]; then
  install_deps || die "dependency install failed"
fi

INSTALL_DIR="$(choose_install_dir)"
mkdir -p "$INSTALL_DIR"

BDTOOL_RAW_URL="https://raw.githubusercontent.com/My15sir/PT-BDtool/main/bdtool.sh"
execute_with_spinner "下载 bdtool" dl_to_file "$BDTOOL_RAW_URL" "$INSTALL_DIR/bdtool" || die "failed to download bdtool"
chmod +x "$INSTALL_DIR/bdtool"

ensure_path_for_user_dir "$INSTALL_DIR"
if ! need_cmd BDInfo; then
  install_bdinfo_cli "$INSTALL_DIR" || log_warn "BDInfo install failed, continue"
fi

if need_cmd BDInfo; then
  log_success "BDInfo is available"
else
  log_warn "BDInfo is missing, please configure PATH or install manually"
fi

msg "安装完成" "Install completed"
msg "下一步：bdtool doctor" "Next: bdtool doctor"
