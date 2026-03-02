#!/usr/bin/env bash
set -euo pipefail

# PT-BDtool installer
# Usage:
#   bash <(wget -qO- https://raw.githubusercontent.com/My15sir/PT-BDtool/main/install.sh) [-k]
# Options:
#   -k  自动安装依赖：ffmpeg / mediainfo / docker（以及基础工具）

DO_K="0"
while getopts ":k" opt; do
  case "$opt" in
    k) DO_K="1" ;;
    *) ;;
  esac
done

log(){ echo "[bdtool-install] $*"; }
die(){ echo "[bdtool-install][ERROR] $*" >&2; exit 1; }

need_cmd(){ command -v "$1" >/dev/null 2>&1; }

is_root(){ [[ "${EUID:-$(id -u)}" -eq 0 ]]; }

sudo_cmd(){
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

start_docker_best_effort(){
  local SUDO
  SUDO="$(sudo_cmd)"
  if need_cmd systemctl; then
    $SUDO systemctl enable --now docker >/dev/null 2>&1 || true
  elif need_cmd service; then
    $SUDO service docker start >/dev/null 2>&1 || true
  fi
}

install_deps(){
  local SUDO
  SUDO="$(sudo_cmd)"

  if need_cmd apt-get; then
    $SUDO apt-get update -y
    # docker.io: Debian/Ubuntu 仓库版（足够用、最省事）
    $SUDO apt-get install -y ca-certificates curl wget git ffmpeg mediainfo docker.io
    start_docker_best_effort
    return 0
  fi

  if need_cmd dnf; then
    $SUDO dnf makecache -y || true
    # docker：部分发行版包名为 docker 或 moby-engine（这里先尝试 docker）
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
    # Alpine 使用 OpenRC 的场景
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

log "start (k=$DO_K)"

if [[ "$DO_K" == "1" ]]; then
  log "install deps: ffmpeg mediainfo docker"
  install_deps
fi

BDTOOL_RAW_URL="https://raw.githubusercontent.com/My15sir/PT-BDtool/main/bdtool.sh"

mkdir -p "$HOME/bin"
dl "$BDTOOL_RAW_URL" > "$HOME/bin/bdtool"
chmod +x "$HOME/bin/bdtool"

# ensure PATH
if ! echo "$PATH" | grep -q "$HOME/bin"; then
  if [[ -f "$HOME/.bashrc" ]] && ! grep -q 'export PATH="$HOME/bin:$PATH"' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
  fi
  export PATH="$HOME/bin:$PATH"
fi

log "installed: $HOME/bin/bdtool"
"$HOME/bin/bdtool" --help >/dev/null 2>&1 || true
log "done"
