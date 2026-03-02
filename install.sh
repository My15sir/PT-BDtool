#!/usr/bin/env bash
set -euo pipefail

# PT-BDtool installer
# 用法：
#   bash <(curl -fsSL https://raw.githubusercontent.com/My15sir/PT-BDtool/main/install.sh) [-k]
# 选项：
#   -k  自动安装依赖：ffmpeg / mediainfo / docker（以及基础工具）

DO_K="0"
while getopts ":k" opt; do
  case "$opt" in
    k) DO_K="1" ;;
    *) ;;
  esac
done

log() { echo "[bdtool-install] $*"; }
die() { echo "[bdtool-install][ERROR] $*" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1; }
is_root() { [[ "${EUID:-$(id -u)}" -eq 0 ]]; }

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
    $SUDO apt-get update -y
    $SUDO apt-get install -y ca-certificates curl wget git ffmpeg mediainfo docker.io
    start_docker_best_effort
    return 0
  fi

  if need_cmd dnf; then
    $SUDO dnf makecache -y || true
    $SUDO dnf install -y ca-certificates curl wget git ffmpeg mediainfo docker || true
    start_docker_best_effort
    return 0
  fi

  if need_cmd yum; then
    $SUDO yum makecache -y || true
    $SUDO yum install -y ca-certificates curl wget git ffmpeg mediainfo docker || true
    start_docker_best_effort
    return 0
  fi

  if need_cmd apk; then
    $SUDO apk add --no-cache ca-certificates curl wget git ffmpeg mediainfo docker
    $SUDO rc-update add docker default >/dev/null 2>&1 || true
    $SUDO service docker start >/dev/null 2>&1 || true
    return 0
  fi

  if need_cmd pacman; then
    $SUDO pacman -Sy --noconfirm ca-certificates curl wget git ffmpeg mediainfo docker
    start_docker_best_effort
    return 0
  fi

  die "未识别到包管理器（apt/dnf/yum/apk/pacman），无法自动安装依赖"
}

choose_install_dir() {
  # root：优先 /usr/local/bin（基本都在 PATH）
  if is_root; then
    if [[ -d "/usr/local/bin" && -w "/usr/local/bin" ]]; then
      echo "/usr/local/bin"
      return 0
    fi
    # 兜底：root 家目录 bin（可能不在 PATH，但后面会提示）
    echo "$HOME/bin"
    return 0
  fi

  # 非 root：优先 ~/.local/bin（更通用），否则 ~/bin
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

  # /usr/local/bin 这类系统目录一般已在 PATH，无需处理
  case "$dir" in
    /usr/local/bin|/usr/bin|/bin|/usr/sbin|/sbin) return 0 ;;
  esac

  # 若当前 PATH 没包含该目录，则写入 ~/.bashrc（尽量不改别的 shell）
  if ! echo ":$PATH:" | grep -q ":$dir:"; then
    if [[ -f "$HOME/.bashrc" ]]; then
      if ! grep -qF "export PATH=\"$dir:\$PATH\"" "$HOME/.bashrc"; then
        echo "export PATH=\"$dir:\$PATH\"" >> "$HOME/.bashrc"
      fi
    fi
    export PATH="$dir:$PATH"
    log "提示：已临时加入 PATH。建议执行：source ~/.bashrc 或重新打开终端。"
  fi
}

log "start (k=$DO_K)"

if [[ "$DO_K" == "1" ]]; then
  log "install deps: ffmpeg mediainfo docker"
  install_deps
fi

BDTOOL_RAW_URL="https://raw.githubusercontent.com/My15sir/PT-BDtool/main/bdtool.sh"
INSTALL_DIR="$(choose_install_dir)"
mkdir -p "$INSTALL_DIR"

dl "$BDTOOL_RAW_URL" > "$INSTALL_DIR/bdtool"
chmod +x "$INSTALL_DIR/bdtool"

ensure_path_for_user_dir "$INSTALL_DIR"

log "installed: $INSTALL_DIR/bdtool"
"$INSTALL_DIR/bdtool" --help >/dev/null 2>&1 || true
log "done"
