#!/usr/bin/env bash
set -euo pipefail

# BDTool one-line installer
# Usage:
#   bash <(wget -qO- RAW_URL) [-k]
# Options:
#   -k  (预留) 未来用于自动安装依赖/自动配置等

DO_K="0"
while getopts ":k" opt; do
  case "$opt" in
    k) DO_K="1" ;;
    *) ;;
  esac
done

echo "[bdtool-install] start (k=$DO_K)"

# --- downloader (wget/curl) ---
dl() {
  local url="$1"
  if command -v wget >/dev/null 2>&1; then
    wget -qO- "$url"
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url"
  else
    echo "[ERROR] need wget or curl" >&2
    exit 1
  fi
}

# TODO: 把下面 URL 改成你仓库里的 bdtool.sh raw 地址
BDTOOL_RAW_URL="__REPLACE_WITH_BDTOOL_SH_RAW_URL__"

mkdir -p "$HOME/bin"
dl "$BDTOOL_RAW_URL" > "$HOME/bin/bdtool"
chmod +x "$HOME/bin/bdtool"

# ensure PATH
if ! echo "$PATH" | grep -q "$HOME/bin"; then
  if [ -f "$HOME/.bashrc" ] && ! grep -q 'export PATH="$HOME/bin:$PATH"' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
  fi
  export PATH="$HOME/bin:$PATH"
fi

echo "[bdtool-install] installed to $HOME/bin/bdtool"
"$HOME/bin/bdtool" --help >/dev/null 2>&1 || true
echo "[bdtool-install] done"
