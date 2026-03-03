#!/usr/bin/env bash
set -euo pipefail

# =====================
# Module: core
# =====================
APP_NAME="bdtool"

bt_die() { echo "[ERROR] $*" >&2; exit 1; }
bt_log() {
  local level="${OPT_LOG_LEVEL:-normal}"
  [[ "$level" == "quiet" ]] && return 0
  echo "[$APP_NAME] $*"
}
bt_debug() {
  local level="${OPT_LOG_LEVEL:-normal}"
  [[ "$level" == "debug" ]] || return 0
  echo "[$APP_NAME][DEBUG] $*"
}
bt_need_cmd() { command -v "$1" >/dev/null 2>&1 || bt_die "缺少依赖命令：$1"; }

bt_safe_name() {
  local s="$1"
  s="${s//\//_}"
  s="${s//$'\n'/ }"
  s="${s//$'\r'/ }"
  s="$(echo "$s" | sed 's/[[:space:]]\+/ /g; s/^ *//; s/ *$//')"
  [[ -z "$s" ]] && s="unknown"
  echo "$s"
}

bt_mk_task_dir() {
  local base_out="$1"
  local label="$2"
  local ts
  ts="$(date +"%Y%m%d_%H%M%S")"
  local dir
  dir="$base_out/${ts}__$(bt_safe_name "$label")"
  mkdir -p "$dir"
  echo "$dir"
}

bt_is_positive_int() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

# =====================
# Module: discover
# =====================
bt_find_video_files() {
  local base="$1"
  find "$base" -type f \( \
    -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.m2ts" -o -iname "*.ts" -o \
    -iname "*.avi" -o -iname "*.mov" -o -iname "*.wmv" -o -iname "*.webm" -o \
    -iname "*.mpg" -o -iname "*.mpeg" \
  \) 2>/dev/null | sort -u
}

bt_is_video_file() {
  local p="$1"
  local l
  l="$(echo "$p" | tr '[:upper:]' '[:lower:]')"
  case "$l" in
    *.mkv|*.mp4|*.m2ts|*.ts|*.avi|*.mov|*.wmv|*.webm|*.mpg|*.mpeg) return 0 ;;
    *) return 1 ;;
  esac
}

bt_resolve_bd_path() {
  local p="$1"
  if [[ -f "$p" ]]; then
    local l
    l="$(echo "$p" | tr '[:upper:]' '[:lower:]')"
    [[ "$l" == *.iso ]] && { echo "$p"; return 0; }
    return 1
  fi

  if [[ -d "$p" ]]; then
    if [[ -d "$p/BDMV" ]]; then
      echo "$p/BDMV"
      return 0
    fi
    if [[ "$(basename "$p")" == "BDMV" && -d "$p/STREAM" && -d "$p/PLAYLIST" ]]; then
      echo "$p"
      return 0
    fi
  fi
  return 1
}

# =====================
# Module: media
# =====================
bt_pick_random_seconds() {
  local duration_s="$1"
  local n="$2"

  local dur_int="${duration_s%.*}"
  [[ -z "$dur_int" || "$dur_int" -lt 1 ]] && dur_int=1

  local start=0
  local end="$dur_int"
  if [[ "$dur_int" -ge 120 ]]; then
    start=$((dur_int / 20))
    end=$((dur_int - dur_int / 20))
    [[ "$end" -le "$start" ]] && { start=0; end="$dur_int"; }
  fi

  local i=1
  while [[ "$i" -le "$n" ]]; do
    local r
    r="$(od -An -N2 -tu2 /dev/urandom | tr -d ' ')"
    local span=$((end - start))
    [[ "$span" -lt 1 ]] && span=1
    echo $((start + (r % span)))
    i=$((i + 1))
  done
}

bt_make_screenshots() {
  local video="$1"
  local info_dir="$2"
  local _n_ignored="${3:-}"
  local n=6

  bt_need_cmd ffprobe
  bt_need_cmd ffmpeg

  local duration
  duration="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video" || true)"
  [[ -z "$duration" ]] && bt_die "无法读取视频时长：$video"

  mkdir -p "$info_dir"

  local idx=1
  while read -r sec; do
    ffmpeg -nostdin -hide_banner -loglevel error -ss "$sec" -i "$video" -frames:v 1 -y "$info_dir/${idx}.png"
    idx=$((idx + 1))
  done < <(bt_pick_random_seconds "$duration" "$n")
}

bt_run_mediainfo_report() {
  local video="$1"
  local info_dir="$2"

  bt_need_cmd mediainfo
  mkdir -p "$info_dir"
  mediainfo "$video" > "$info_dir/mediainfo.txt"
}

bt_run_bdinfo_report() {
  local bd_path="$1"
  local info_dir="$2"

  bt_need_cmd BDInfo
  mkdir -p "$info_dir"

  bt_log "BDInfo: run on $bd_path"
  BDInfo -w "$bd_path" "$info_dir"

  local latest_txt
  latest_txt="$(find "$info_dir" -maxdepth 1 -type f -name '*.txt' ! -name 'bdinfo.txt' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2- || true)"
  if [[ -n "$latest_txt" && -f "$latest_txt" ]]; then
    cp -f "$latest_txt" "$info_dir/bdinfo.txt"
    return 0
  fi

  [[ -f "$info_dir/bdinfo.txt" ]] || bt_die "BDInfo 已执行，但未在 $info_dir 发现可归档的报告文件"
}

# =====================
# Module: defaults/config
# =====================
: "${OPT_MEDIAINFO:=1}"
: "${OPT_SHOTS:=1}"
: "${OPT_SHOTS_N:=}"
: "${OPT_JOBS:=}"
: "${OPT_LOG_LEVEL:=normal}"

bt_default_jobs() {
  local n=1
  if command -v nproc >/dev/null 2>&1; then
    n="$(nproc)"
  elif command -v getconf >/dev/null 2>&1; then
    n="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
  fi
  [[ "$n" =~ ^[0-9]+$ ]] || n=1
  [[ "$n" -lt 1 ]] && n=1
  [[ "$n" -gt 4 ]] && n=4
  echo "$n"
}

bt_infer_out_dir() {
  local scan_path="$1"
  local base="./bdtool-output"
  if [[ -d "$scan_path" ]]; then
    local name
    name="$(basename "$scan_path")"
    echo "$base/$(bt_safe_name "$name")"
  else
    echo "$base"
  fi
}

bt_validate_options() {
  bt_is_positive_int "$OPT_SHOTS_N" || bt_die "--shots 必须是正整数"
  bt_is_positive_int "$OPT_JOBS" || bt_die "--jobs 必须是正整数"
}

# =====================
# Module: jobs
# =====================
bt_run_with_jobs() {
  local jobs="$1"
  shift

  local running=0
  local cmd
  for cmd in "$@"; do
    bash -c "$cmd" &
    running=$((running + 1))
    if [[ "$running" -ge "$jobs" ]]; then
      wait -n
      running=$((running - 1))
    fi
  done
  wait
}

# =====================
# Module: worker
# =====================
bt_process_video_file() {
  local video="$1"
  local base_out="$2"

  local name
  name="$(basename "$video")"

  local jobdir
  jobdir="$(bt_mk_task_dir "$base_out" "$name")"
  local info_dir="$jobdir/信息"
  mkdir -p "$info_dir"

  bt_log "VIDEO: $video"
  bt_log "OUT:   $jobdir"
  bt_log "OPTS:  mediainfo=$OPT_MEDIAINFO shots=$OPT_SHOTS shots_n=$OPT_SHOTS_N"

  if [[ "$OPT_MEDIAINFO" != "1" && "$OPT_SHOTS" != "1" ]]; then
    echo "本次已关闭 mediainfo 与 screenshots，因此该目录为空（这是预期行为）。" > "$jobdir/README.txt"
    return 0
  fi

  if [[ "$OPT_MEDIAINFO" == "1" ]]; then
    bt_run_mediainfo_report "$video" "$info_dir"
  fi

  if [[ "$OPT_SHOTS" == "1" ]]; then
    bt_make_screenshots "$video" "$info_dir" "$OPT_SHOTS_N"
  fi

  bt_log "BDInfo: skipped (非 BDMV/ISO 输入)"
}

bt_worker_entry() {
  OPT_MEDIAINFO="${OPT_MEDIAINFO:-1}"
  OPT_SHOTS="${OPT_SHOTS:-1}"
  OPT_SHOTS_N="${OPT_SHOTS_N:-4}"

  local video="$1"
  local out_base="$2"
  bt_process_video_file "$video" "$out_base"
}

# =====================
# Module: scan
# =====================
bt_process_local_scan() {
  local scan_path="$1"
  local out_base="$2"

  mkdir -p "$out_base"
  local task_out
  task_out="$(bt_mk_task_dir "$out_base" "scan_$(bt_safe_name "$scan_path")")"

  bt_log "SCAN:  $scan_path"
  bt_log "TASK:  $task_out"
  bt_log "OPTS:  mediainfo=$OPT_MEDIAINFO shots=$OPT_SHOTS shots_n=$OPT_SHOTS_N jobs=$OPT_JOBS"
  bt_debug "scan_path_type=$( [[ -f "$scan_path" ]] && echo file || echo dir )"

  local bd_path=""
  if bd_path="$(bt_resolve_bd_path "$scan_path")"; then
    local info_dir="$task_out/信息"
    bt_run_bdinfo_report "$bd_path" "$info_dir"
    bt_log "MediaInfo/Screenshots: skipped (BDMV/ISO 输入)"
    echo "$task_out"
    return 0
  fi

  if [[ -f "$scan_path" ]]; then
    bt_is_video_file "$scan_path" || bt_die "不支持的文件类型：$scan_path（仅视频文件或 Blu-ray BDMV/ISO）"
    export OPT_MEDIAINFO OPT_SHOTS OPT_SHOTS_N OPT_LOG_LEVEL
    bash -c "$(printf '%q ' "$0") __worker_video $(printf '%q ' "$scan_path") $(printf '%q' "$task_out")"
    echo "$task_out"
    return 0
  fi

  local video_list=()
  while IFS= read -r vf; do
    [[ -n "$vf" ]] && video_list+=("$vf")
  done < <(bt_find_video_files "$scan_path")

  [[ "${#video_list[@]}" -gt 0 ]] || bt_die "未发现视频文件：$scan_path"

  local cmds=()
  local v
  export OPT_MEDIAINFO OPT_SHOTS OPT_SHOTS_N OPT_LOG_LEVEL
  for v in "${video_list[@]}"; do
    cmds+=("$(printf '%q ' "$0") __worker_video $(printf '%q ' "$v") $(printf '%q' "$task_out")")
  done

  if [[ "$OPT_JOBS" -le 1 ]]; then
    local c
    for c in "${cmds[@]}"; do bash -c "$c"; done
  else
    bt_run_with_jobs "$OPT_JOBS" "${cmds[@]}"
  fi

  echo "$task_out"
}

# =====================
# Module: cli
# =====================
bt_usage() {
  cat <<'USAGE'
bdtool <path> [options]
bdtool scan <path> --out <dir> [options]  # 兼容入口
bdtool doctor
bdtool status  Check installation status
bdtool install
bdtool clean

options:
  --log-level LEVEL  日志级别：quiet|normal|debug（默认 normal）
  --quiet            等价于 --log-level quiet
  --no-mediainfo     不生成 MediaInfo
  --no-shots         不截图
  --mode dry         等价于 --no-shots --no-mediainfo
  --shots N          参数保留；最终固定输出 6 张截图（1.png..6.png）
  -s N               等价于 --shots N
  --jobs N           并行任务数（默认 1）
  -j N               等价于 --jobs N
  --out DIR          输出目录（新入口默认 ./bdtool-output）

examples:
  ./bdtool.sh movie.mkv
  ./bdtool.sh /data/videos -s 6 -j 2
  ./bdtool.sh movie.mkv --log-level debug
  ./bdtool.sh scan /data/videos --out output
  ./bdtool.sh install
  ./bdtool.sh clean
USAGE
}

bt_cmd_doctor() {
  echo "== doctor =="
  local c
  for c in find sort od awk sed; do
    command -v "$c" >/dev/null 2>&1 && echo "OK: $c" || echo "MISS: $c"
  done
  for c in ffmpeg ffprobe mediainfo; do
    command -v "$c" >/dev/null 2>&1 && echo "OK: $c" || echo "MISS: $c"
  done
  if command -v BDInfo >/dev/null 2>&1; then
    echo "OK: BDInfo"
  else
    echo "MISS: BDInfo (安装提示：运行 install.sh，Linux x64 会自动安装 BDInfoCLI-ng)"
  fi
}

bt_try_version_cmd() {
  local out
  if out="$("$@" 2>/dev/null)"; then
    out="$(echo "$out" | head -n 1)"
    [[ -n "$out" ]] && { echo "$out"; return 0; }
  fi
  return 1
}

bt_cmd_status() {
  local locale="${LC_ALL:-${LANG:-}}"
  local is_zh=0
  [[ "$locale" == *zh* || "$locale" == *ZH* ]] && is_zh=1

  local install_path
  install_path="$(command -v bdtool 2>/dev/null || true)"
  [[ -n "$install_path" ]] || install_path="$0"

  local version="unknown"
  if bt_try_version_cmd bdtool --version >/dev/null 2>&1; then
    version="$(bt_try_version_cmd bdtool --version)"
  elif bt_try_version_cmd "$0" --version >/dev/null 2>&1; then
    version="$(bt_try_version_cmd "$0" --version)"
  elif command -v git >/dev/null 2>&1 && git rev-parse --short HEAD >/dev/null 2>&1; then
    version="$(git rev-parse --short HEAD)"
  fi

  if [[ "$is_zh" == "1" ]]; then
    echo "[bdtool] 安装路径：$install_path"
    echo "[bdtool] 版本：$version"
    echo "[bdtool] 依赖检查："
  else
    echo "[bdtool] Install path: $install_path"
    echo "[bdtool] Version: $version"
    echo "[bdtool] Dependency check:"
  fi

  local fail=0
  local dep
  for dep in ffmpeg ffprobe mediainfo BDInfo; do
    if command -v "$dep" >/dev/null 2>&1; then
      echo "  OK: $dep"
    else
      echo "  MISS: $dep"
      fail=1
    fi
  done

  if [[ "$is_zh" == "1" ]]; then
    if [[ "$fail" -eq 0 ]]; then
      echo "[bdtool] 结果：PASS"
    else
      echo "[bdtool] 结果：FAIL"
    fi
  else
    if [[ "$fail" -eq 0 ]]; then
      echo "[bdtool] Result: PASS"
    else
      echo "[bdtool] Result: FAIL"
    fi
  fi

  return "$fail"
}

bt_cmd_install() {
  if ./install.sh && "$0" doctor; then
    echo "INSTALL OK"
  else
    echo "INSTALL FAIL"
    exit 1
  fi
}

bt_cmd_clean() {
  local target="./bdtool-output"
  [[ "$target" == "./bdtool-output" ]] || bt_die "clean safety check failed"

  if [[ -d "$target" ]]; then
    rm -rf -- "$target"
    bt_log "cleaned: $target"
  else
    echo "nothing to clean"
  fi
}

bt_main_scan() {
  local scan_path="$1"
  shift

  local out_dir=""
  local quiet=0
  local default_jobs
  default_jobs="$(bt_default_jobs)"

  OPT_MEDIAINFO="${OPT_MEDIAINFO:-1}"
  OPT_SHOTS="${OPT_SHOTS:-1}"
  OPT_SHOTS_N="${OPT_SHOTS_N:-4}"
  OPT_JOBS="${OPT_JOBS:-$default_jobs}"
  OPT_LOG_LEVEL="${OPT_LOG_LEVEL:-normal}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --log-level)
        [[ $# -ge 2 && -n "${2:-}" && "${2:0:1}" != "-" ]] || { echo "ERROR: --log-level requires a value. Example: ./bdtool.sh <path> --log-level debug" >&2; exit 1; }
        case "$2" in
          quiet|normal|debug) OPT_LOG_LEVEL="$2" ;;
          *) echo "ERROR: invalid log level: $2. Use quiet|normal|debug" >&2; exit 1 ;;
        esac
        shift 2
        ;;
      --out)
        [[ $# -ge 2 && -n "${2:-}" && "${2:0:1}" != "-" ]] || { echo "ERROR: --out requires a value. Example: ./bdtool.sh scan <path> --out ./bdtool-output" >&2; exit 1; }
        out_dir="${2:-}"
        shift 2
        ;;
      --no-mediainfo) OPT_MEDIAINFO=0; shift 1 ;;
      --no-shots) OPT_SHOTS=0; shift 1 ;;
      --mode)
        [[ $# -ge 2 && -n "${2:-}" && "${2:0:1}" != "-" ]] || { echo "ERROR: --mode requires a value. Example: ./bdtool.sh <path> --mode dry" >&2; exit 1; }
        if [[ "$2" == "dry" ]]; then
          OPT_MEDIAINFO=0
          OPT_SHOTS=0
        else
          echo "ERROR: unsupported mode: $2. Example: ./bdtool.sh <path> --mode dry" >&2
          exit 1
        fi
        shift 2
        ;;
      --shots)
        [[ $# -ge 2 && -n "${2:-}" && "${2:0:1}" != "-" ]] || { echo "ERROR: --shots requires a value. Example: ./bdtool.sh <path> --shots 4" >&2; exit 1; }
        OPT_SHOTS_N="${2:-}"
        shift 2
        ;;
      -s)
        [[ $# -ge 2 && -n "${2:-}" && "${2:0:1}" != "-" ]] || { echo "ERROR: -s requires a value. Example: ./bdtool.sh <path> -s 4" >&2; exit 1; }
        OPT_SHOTS_N="${2:-}"
        shift 2
        ;;
      --jobs)
        [[ $# -ge 2 && -n "${2:-}" && "${2:0:1}" != "-" ]] || { echo "ERROR: --jobs requires a value. Example: ./bdtool.sh <path> --jobs 2" >&2; exit 1; }
        OPT_JOBS="${2:-}"
        shift 2
        ;;
      -j)
        [[ $# -ge 2 && -n "${2:-}" && "${2:0:1}" != "-" ]] || { echo "ERROR: -j requires a value. Example: ./bdtool.sh <path> -j 2" >&2; exit 1; }
        OPT_JOBS="${2:-}"
        shift 2
        ;;
      --quiet) quiet=1; shift 1 ;;
      -h|--help) bt_usage; exit 0 ;;
      *) bt_die "未知参数：$1。示例：./bdtool.sh <path> --mode dry" ;;
    esac
  done

  if [[ "$quiet" == "1" ]]; then
    OPT_LOG_LEVEL="quiet"
  fi

  [[ -e "$scan_path" ]] || bt_die "路径不存在：$scan_path。示例：./bdtool.sh ./movie.mkv --mode dry"
  if [[ -z "$out_dir" ]]; then
    out_dir="$(bt_infer_out_dir "$scan_path")"
    bt_log "OUT(auto): $out_dir"
  fi

  bt_debug "effective options: mediainfo=$OPT_MEDIAINFO shots=$OPT_SHOTS shots_n=$OPT_SHOTS_N jobs=$OPT_JOBS log_level=$OPT_LOG_LEVEL"
  OPT_SHOTS_N=6
  bt_validate_options

  if [[ "$OPT_LOG_LEVEL" == "quiet" ]]; then
    bt_process_local_scan "$scan_path" "$out_dir" >/dev/null
  else
    bt_process_local_scan "$scan_path" "$out_dir"
  fi
}

bt_main() {
  if [[ "${1:-}" == "__worker_video" ]]; then
    shift
    bt_worker_entry "$1" "$2"
    exit 0
  fi

  [[ $# -gt 0 ]] || { bt_usage; exit 0; }

  case "$1" in
    scan)
      shift
      [[ $# -ge 1 ]] || bt_die "用法：bdtool scan <path> --out <dir>。示例：./bdtool.sh scan ./movie.mkv --out ./bdtool-output"
      bt_main_scan "$@"
      ;;
    doctor)
      shift
      bt_cmd_doctor
      ;;
    status)
      shift
      bt_cmd_status
      ;;
    install)
      shift
      bt_cmd_install
      ;;
    clean)
      shift
      bt_cmd_clean
      ;;
    -h|--help)
      bt_usage
      ;;
    *)
      if [[ -e "$1" ]]; then
        local default_out="./bdtool-output"
        mkdir -p "$default_out"
        bt_main_scan "$1" --out "$default_out" "${@:2}"
      else
        bt_usage
        bt_die "未知命令或路径不存在：$1。示例：./bdtool.sh ./movie.mkv 或 ./bdtool.sh scan ./movie.mkv --out ./bdtool-output"
      fi
      ;;
  esac
}

bt_main "$@"
