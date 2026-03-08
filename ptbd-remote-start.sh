#!/usr/bin/env bash
set -euo pipefail

run_remote() {
  if command -v ptbd-remote >/dev/null 2>&1; then
    ptbd-remote "$@"
    return $?
  fi

  local script_dir=""
  script_dir="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -x "$script_dir/ptbd-remote.sh" ]]; then
    "$script_dir/ptbd-remote.sh" "$@"
    return $?
  fi

  echo "[ERROR] 找不到 ptbd-remote"
  return 127
}

run_remote "$@"
rc=$?
case "${1:-}" in
  -h|--help|--setup|--show-config) exit "$rc" ;;
esac
if [[ -t 0 && -t 1 ]]; then
  echo
  if [[ "$rc" -eq 0 ]]; then
    echo "处理结束。按回车关闭。"
  else
    echo "执行失败（rc=$rc）。按回车关闭。"
  fi
  read -r _ < /dev/tty || true
fi
exit "$rc"
