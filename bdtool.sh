#!/usr/bin/env bash
set -euo pipefail

APP_NAME="bdtool"

die() { echo "[ERROR] $*" >&2; exit 1; }
log() { echo "[$APP_NAME] $*"; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || die "缺少依赖命令：$1"; }

safe_name() {
  local s="$1"
  s="${s//\//_}"
  s="${s//$'\n'/ }"
  s="${s//$'\r'/ }"
  s="$(echo "$s" | sed 's/[[:space:]]\+/ /g; s/^ *//; s/ *$//')"
  [[ -z "$s" ]] && s="unknown"
  echo "$s"
}

mk_task_dir() {
  local base_out="$1"
  local label="$2"
  local ts
  ts="$(date +"%Y%m%d_%H%M%S")"
  local dir
  dir="$base_out/${ts}__$(safe_name "$label")"
  mkdir -p "$dir"
  echo "$dir"
}

is_bdmv_dir() {
  local bdmv="$1"
  [[ -d "$bdmv/STREAM" && -d "$bdmv/PLAYLIST" ]]
}

find_bdmv_roots() {
  local base="$1"
  find "$base" -type d -name BDMV 2>/dev/null |
    while read -r d; do
      if is_bdmv_dir "$d"; then echo "$d"; fi
    done | sort -u
}

find_video_files() {
  local base="$1"
  find "$base" -type f \( \
    -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.m2ts" -o -iname "*.ts" -o \
    -iname "*.avi" -o -iname "*.mov" -o -iname "*.wmv" -o -iname "*.webm" -o \
    -iname "*.mpg" -o -iname "*.mpeg" \
  \) 2>/dev/null | sort -u
}

pick_random_seconds() {
  local duration_s="$1"
  local n="$2"

  local dur_int="${duration_s%.*}"
  [[ -z "$dur_int" || "$dur_int" -lt 1 ]] && dur_int=1

  local start=0 end="$dur_int"
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

make_screenshots() {
  local video="$1"
  local outdir="$2"
  local n="$3"

  need_cmd ffprobe
  need_cmd ffmpeg

  local duration
  duration="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video" || true)"
  [[ -z "$duration" ]] && die "无法读取视频时长：$video"

  mkdir -p "$outdir/screenshots"

  local idx=1
  while read -r sec; do
    ffmpeg -nostdin -hide_banner -loglevel error -ss "$sec" -i "$video" -frames:v 1 -y "$outdir/screenshots/截图_${idx}.png"
    idx=$((idx + 1))
  done < <(pick_random_seconds "$duration" "$n")
}

run_mediainfo_report() {
  local video="$1"
  local outdir="$2"
  need_cmd mediainfo
  mkdir -p "$outdir/mediainfo"
  mediainfo "$video" > "$outdir/mediainfo/MEDIAINFO.txt"
}

# ===== 选项（默认值）=====
: "${OPT_MEDIAINFO:=1}"
: "${OPT_SHOTS:=1}"
: "${OPT_SHOTS_N:=4}"
: "${OPT_JOBS:=1}"

run_with_jobs() {
  local jobs="$1"; shift
  local running=0
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


process_video_file() {
  local video="$1"
  local base_out="$2"

  local name
  name="$(basename "$video")"

  local jobdir
  jobdir="$(mk_task_dir "$base_out" "$name")"

  log "VIDEO: $video"
  log "OUT:   $jobdir"
  log "OPTS:  mediainfo=$OPT_MEDIAINFO shots=$OPT_SHOTS shots_n=$OPT_SHOTS_N"

  # 两项都关：写说明，避免“空目录像坏了”
  if [[ "$OPT_MEDIAINFO" != "1" && "$OPT_SHOTS" != "1" ]]; then
    echo "本次已关闭 mediainfo 与 screenshots，因此该目录为空（这是预期行为）。" > "$jobdir/README.txt"
    return 0
  fi

  if [[ "$OPT_MEDIAINFO" == "1" ]]; then
    run_mediainfo_report "$video" "$jobdir"
  fi

  if [[ "$OPT_SHOTS" == "1" ]]; then
    make_screenshots "$video" "$jobdir" "$OPT_SHOTS_N"
  fi
}



process_local_scan() {
  local scan_path="$1"
  local out_base="$2"

  mkdir -p "$out_base"
  local task_out
  task_out="$(mk_task_dir "$out_base" "scan_$(safe_name "$scan_path")")"

  log "SCAN:  $scan_path"
  log "TASK:  $task_out"
  log "OPTS:  mediainfo=$OPT_MEDIAINFO shots=$OPT_SHOTS shots_n=$OPT_SHOTS_N jobs=$OPT_JOBS"

  # 传入是文件：只处理这个文件
  if [[ -f "$scan_path" ]]; then
    export OPT_MEDIAINFO OPT_SHOTS OPT_SHOTS_N
    bash -c "$(printf '%q ' "$0") __worker_video $(printf '%q ' "$scan_path") $(printf '%q' "$task_out")"
    echo "$task_out"
    return 0
  fi

  # 传入是目录：扫描目录
  local video_list=()
  while IFS= read -r vf; do
    [[ -n "$vf" ]] && video_list+=("$vf")
  done < <(find_video_files "$scan_path")

  if [[ "${#video_list[@]}" -eq 0 ]]; then
    die "未发现视频文件：$scan_path"
  fi

  local cmds=()
  export OPT_MEDIAINFO OPT_SHOTS OPT_SHOTS_N

  for v in "${video_list[@]}"; do
    cmds+=("$(printf '%q ' "$0") __worker_video $(printf '%q ' "$v") $(printf '%q' "$task_out")")
  done

  if [[ "$OPT_JOBS" -le 1 ]]; then
    for c in "${cmds[@]}"; do bash -c "$c"; done
  else
    run_with_jobs "$OPT_JOBS" "${cmds[@]}"
  fi

  echo "$task_out"
}


usage() {
  cat <<'USAGE'
bdtool scan <dir> --out <dir> [options]
bdtool doctor

options:
  --no-mediainfo     不生成 MediaInfo
  --no-shots         不截图
  --shots N          截图张数（默认 4）
  --jobs N           并行任务数（默认 1）
USAGE
}

cmd_doctor() {
  echo "== doctor =="
  for c in find sort od awk sed; do
    command -v "$c" >/dev/null 2>&1 && echo "OK: $c" || echo "MISS: $c"
  done
  for c in ffmpeg ffprobe mediainfo; do
    command -v "$c" >/dev/null 2>&1 && echo "OK: $c" || echo "MISS: $c"
  done
}


main_scan() {
  local scan_path="$1"; shift
  local out_dir=""
  local quiet=0

  # 顺序无关解析：所有参数一口气吃完
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --out) out_dir="${2:-}"; shift 2 ;;
      --no-mediainfo) OPT_MEDIAINFO=0; shift 1 ;;
      --no-shots) OPT_SHOTS=0; shift 1 ;;
      --shots) OPT_SHOTS_N="${2:-}"; shift 2 ;;
      --jobs) OPT_JOBS="${2:-}"; shift 2 ;;
      --quiet) quiet=1; shift 1 ;;
      -h|--help) usage; exit 0 ;;
      *) die "未知参数：$1" ;;
    esac
  done

  [[ -d "$scan_path" ]] || die "路径不存在：$scan_path"
  [[ -n "$out_dir" ]] || die "缺少 --out <dir>"

  if [[ "$quiet" == "1" ]]; then
    process_local_scan "$scan_path" "$out_dir" >/dev/null
  else
    process_local_scan "$scan_path" "$out_dir"
  fi
}


main() {
  # worker 入口：从环境变量恢复选项
  if [[ "${1:-}" == "__worker_video" ]]; then
    OPT_MEDIAINFO="${OPT_MEDIAINFO:-1}"
    OPT_SHOTS="${OPT_SHOTS:-1}"
    OPT_SHOTS_N="${OPT_SHOTS_N:-4}"
    shift
    process_video_file "$1" "$2"
    exit 0
  fi

  [[ $# -gt 0 ]] || { usage; exit 0; }

  case "$1" in
    scan) shift; [[ $# -ge 1 ]] || die "用法：bdtool scan <dir> --out <dir>"; main_scan "$@" ;;
    doctor) shift; cmd_doctor ;;
    -h|--help) usage ;;
    *) usage; die "未知命令：$1" ;;
  esac
}

main "$@"
