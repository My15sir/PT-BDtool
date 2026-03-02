#!/usr/bin/env bash
set -euo pipefail

# BDTool - one command full pipeline
# - local: scan -> detect BDMV/video -> BDInfo/MediaInfo -> 4 PNG screenshots -> outputs
# - ssh: run same script on remote -> optional pull -> optional clean
#
# Naming rules (per user):
# - report file: BDINFO.bd.txt (always)
# - screenshots: 截图_1.png ... 截图_4.png
# - screenshot resolution: same as source (no scaling)

APP_NAME="bdtool"
DO_PULL="0"
DO_CLEAN="0"
MODE=""
LOCAL_PATH=""
SSH_SPEC=""
OUT_DIR=""

# -------------- helpers --------------
die() { echo "[ERROR] $*" >&2; exit 1; }
log() { echo "[$APP_NAME] $*"; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "缺少依赖命令：$1"
}

safe_name() {
  # make a filesystem safe name (keep CJK, replace slashes, trim)
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
  local dir="$base_out/${ts}__$(safe_name "$label")"
  mkdir -p "$dir"
  echo "$dir"
}

usage() {
  cat <<USAGE
用法：
  本地：
    ./bdtool.sh --local "/path/to/scan" --out "/path/to/output" [--clean]
  远程：
    ./bdtool.sh --ssh "user@ip:/path/to/scan" --out "/path/to/output" [--pull] [--clean]

参数：
  --local   本地扫描根路径
  --ssh     远程扫描根路径，格式 user@ip:/abs/path
  --out     输出目录（本机路径；远程模式下为拉回落地目录）
  --pull    远程模式：拉回远端生成结果到本机（默认不拉回）
  --clean   清理“执行端”的临时目录与产物目录（默认不清理）
  -h|--help 帮助

输出（每个任务一个目录）：
  BDINFO.bd.txt
  截图_1.png ... 截图_4.png
USAGE
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --local) MODE="local"; LOCAL_PATH="${2:-}"; shift 2;;
      --ssh)   MODE="ssh"; SSH_SPEC="${2:-}"; shift 2;;
      --out)   OUT_DIR="${2:-}"; shift 2;;
      --pull)  DO_PULL="1"; shift 1;;
      --clean) DO_CLEAN="1"; shift 1;;
      -h|--help) usage; exit 0;;
      *) die "未知参数：$1";;
    esac
  done

  [[ -z "$MODE" ]] && die "缺少 --local 或 --ssh"
  [[ -z "$OUT_DIR" ]] && die "缺少 --out"
  mkdir -p "$OUT_DIR"
  if [[ "$MODE" == "local" ]]; then
    [[ -z "$LOCAL_PATH" ]] && die "--local 需要路径"
    [[ -d "$LOCAL_PATH" ]] || die "本地路径不存在：$LOCAL_PATH"
  else
    [[ -z "$SSH_SPEC" ]] && die "--ssh 需要 user@ip:/abs/path"
    [[ "$SSH_SPEC" == *:* ]] || die "--ssh 格式必须包含冒号，例如 user@ip:/path"
  fi
}

# -------------- detection --------------
is_bdmv_dir() {
  local bdmv="$1"
  [[ -d "$bdmv/STREAM" && -d "$bdmv/PLAYLIST" ]]
}

find_bdmv_roots() {
  local base="$1"
  # output: full path to BDMV dir that looks like a disc
  find "$base" -type d -name BDMV 2>/dev/null | while read -r d; do
    if is_bdmv_dir "$d"; then
      echo "$d"
    fi
  done | sort -u
}

find_video_files() {
  local base="$1"
  # common extensions
  find "$base" -type f \( \
    -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.m2ts" -o -iname "*.ts" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.wmv" -o -iname "*.webm" -o -iname "*.mpg" -o -iname "*.mpeg" \
  \) 2>/dev/null | sort -u
}

# -------------- screenshots --------------
pick_random_seconds() {
  local duration_s="$1" # float string
  local n="$2"
  local dur_int
  dur_int="${duration_s%.*}"
  [[ -z "$dur_int" || "$dur_int" -lt 1 ]] && dur_int=1

  # avoid first/last 5% if long enough
  local start=0
  local end=$dur_int
  if [[ "$dur_int" -ge 120 ]]; then
    start=$((dur_int / 20))        # 5%
    end=$((dur_int - dur_int/20))  # 95%
    [[ "$end" -le "$start" ]] && { start=0; end=$dur_int; }
  fi

  local i=1
  while [[ "$i" -le "$n" ]]; do
    local r
    r="$(od -An -N2 -tu2 /dev/urandom | tr -d ' ')"
    local span=$((end - start))
    [[ "$span" -lt 1 ]] && span=1
    local sec=$(( start + (r % span) ))
    echo "$sec"
    i=$((i+1))
  done
}

make_screenshots() {
  local video="$1"
  local outdir="$2"
  local n=4

  need_cmd ffprobe
  need_cmd ffmpeg

  local duration
  duration="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video" || true)"
  [[ -z "$duration" ]] && die "无法读取视频时长：$video"

  local idx=1
  pick_random_seconds "$duration" "$n" | while read -r sec; do
    local out="$outdir/截图_${idx}.png"
    ffmpeg -hide_banner -loglevel error -ss "$sec" -i "$video" -frames:v 1 -y "$out"
    idx=$((idx+1))
  done
}

# -------------- BDInfo (docker) --------------
bdinfo_longest_mpls() {
  local bdroot="$1"

  need_cmd docker
  # list mode and pick longest MPLS based on time field (HH:MM:SS)
  docker run --rm -i -v "$bdroot":/mnt/bd fr3akyphantom/bdinfocli-ng -l /mnt/bd \
    | awk '$3 ~ /\.MPLS$/ {split($4,t,":"); s=t[1]*3600+t[2]*60+t[3]; if(s>m){m=s; f=$3}} END{print f}'
}

run_bdinfo_report() {
  local bdroot="$1"
  local mpls="$2"
  local outdir="$3"

  need_cmd docker

  mkdir -p "$outdir"
  # generate into outdir; then normalize to BDINFO.bd.txt
  docker run --rm \
    -v "$bdroot":/mnt/bd \
    -v "$outdir":/mnt/out \
    fr3akyphantom/bdinfocli-ng -m "$mpls" /mnt/bd /mnt/out

  # normalize output name
  local found=""
  found="$(find "$outdir" -maxdepth 1 -type f \( -name "*.bd.txt" -o -name "*.txt" \) | head -n 1 || true)"
  if [[ -n "$found" ]]; then
    mv -f "$found" "$outdir/BDINFO.bd.txt"
  else
    # if image wrote elsewhere or nothing created, create placeholder
    echo "BDInfo 未生成输出文件（请检查 docker/bdinfocli-ng 输出）" > "$outdir/BDINFO.bd.txt"
  fi
}

# -------------- MediaInfo --------------
run_mediainfo_report() {
  local video="$1"
  local outdir="$2"

  need_cmd mediainfo
  mkdir -p "$outdir"
  {
    echo "=== MediaInfo ==="
    echo "FILE: $video"
    echo ""
    mediainfo "$video"
  } > "$outdir/BDINFO.bd.txt"
}

# -------------- process jobs --------------
process_bdmv() {
  local bdmv_dir="$1"
  local base_out="$2"

  local bdroot name stream_dir video jobdir mpls
  bdroot="$(dirname "$bdmv_dir")"
  name="$(basename "$bdroot")"
  jobdir="$(mk_task_dir "$base_out" "$name")"

  log "BDMV: $bdroot"
  log "输出: $jobdir"

  mpls="$(bdinfo_longest_mpls "$bdroot")"
  [[ -z "$mpls" ]] && die "未找到 MPLS（BDInfo list 为空）：$bdroot"
  log "最长 MPLS: $mpls"

  run_bdinfo_report "$bdroot" "$mpls" "$jobdir"

  stream_dir="$bdmv_dir/STREAM"
  video="$(find "$stream_dir" -type f -name "*.m2ts" -printf "%s %p\n" 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2- || true)"
  [[ -z "$video" ]] && die "未找到 m2ts：$stream_dir"
  make_screenshots "$video" "$jobdir"

  log "完成：$jobdir"
}

process_video_file() {
  local video="$1"
  local base_out="$2"

  local name jobdir
  name="$(basename "$video")"
  jobdir="$(mk_task_dir "$base_out" "$name")"

  log "VIDEO: $video"
  log "输出: $jobdir"

  run_mediainfo_report "$video" "$jobdir"
  make_screenshots "$video" "$jobdir"

  log "完成：$jobdir"
}

process_local_scan() {
  local scan_path="$1"
  local out_base="$2"

  # dependencies for scanning
  need_cmd find
  need_cmd sort

  local task_out
  task_out="$(mk_task_dir "$out_base" "scan_$(safe_name "$scan_path")")"
  log "扫描：$scan_path"
  log "任务目录：$task_out"

  # 1) BDMV discs
  local bdmv_list=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && bdmv_list+=("$line")
  done < <(find_bdmv_roots "$scan_path")

  # 2) video files (exclude those under any BDMV dir to avoid duplicates)
  local video_list=()
  while IFS= read -r vf; do
    [[ -z "$vf" ]] && continue
    # skip if path contains /BDMV/ (common)
    if [[ "$vf" == *"/BDMV/"* ]]; then
      continue
    fi
    video_list+=("$vf")
  done < <(find_video_files "$scan_path")

  if [[ "${#bdmv_list[@]}" -eq 0 && "${#video_list[@]}" -eq 0 ]]; then
    die "未发现 BDMV 或视频文件：$scan_path"
  fi

  # process BDMV
  if [[ "${#bdmv_list[@]}" -gt 0 ]]; then
    log "发现 BDMV 数量：${#bdmv_list[@]}"
    for b in "${bdmv_list[@]}"; do
      process_bdmv "$b" "$task_out"
    done
  fi

  # process videos
  if [[ "${#video_list[@]}" -gt 0 ]]; then
    log "发现视频文件数量：${#video_list[@]}"
    for v in "${video_list[@]}"; do
      process_video_file "$v" "$task_out"
    done
  fi

  echo "$task_out"
}

# -------------- SSH mode --------------
ssh_userhost_and_path() {
  # input: user@host:/abs/path
  local spec="$1"
  local userhost="${spec%%:*}"
  local path="${spec#*:}"
  echo "$userhost" "$path"
}

run_ssh_mode() {
  need_cmd ssh
  need_cmd scp

  local userhost remote_path
  read -r userhost remote_path < <(ssh_userhost_and_path "$SSH_SPEC")

  [[ -n "$userhost" ]] || die "ssh spec 无效：$SSH_SPEC"
  [[ -n "$remote_path" ]] || die "ssh spec 无效：$SSH_SPEC"

  # create remote temp workspace
  local ts
  ts="$(date +"%Y%m%d_%H%M%S")"
  local remote_work="/tmp/${APP_NAME}_${ts}_$$"
  local remote_out="${remote_work}/out"

  log "远程主机：$userhost"
  log "远程扫描：$remote_path"
  log "远程工作目录：$remote_work"

  ssh "$userhost" "mkdir -p '$remote_work' '$remote_out'" >/dev/null

  # upload this script to remote
  scp -q "$0" "${userhost}:${remote_work}/bdtool.sh"
  ssh "$userhost" "chmod +x '${remote_work}/bdtool.sh'"

  # run remote as local mode on remote machine
  log "开始远程执行（在远端生成报告与截图）..."
  ssh "$userhost" "'${remote_work}/bdtool.sh' --local '$remote_path' --out '$remote_out' ${DO_CLEAN:+} >/dev/null 2>&1" || {
    # rerun with output to show error
    ssh "$userhost" "'${remote_work}/bdtool.sh' --local '$remote_path' --out '$remote_out'" || true
    die "远程执行失败（请看上方输出）"
  }

  # find newest task dir under remote_out
  local remote_task
  remote_task="$(ssh "$userhost" "ls -1dt '$remote_out'/* 2>/dev/null | head -n1" | tr -d '\r' || true)"
  [[ -n "$remote_task" ]] || die "远端未生成任务目录：$remote_out"

  log "远端任务目录：$remote_task"

  # pull back if requested
  if [[ "$DO_PULL" == "1" ]]; then
    local host_tag
    host_tag="$(echo "$userhost" | sed 's/@/_/g; s/[^A-Za-z0-9._-]/_/g')"
    local local_pull_dir
    local_pull_dir="$(mk_task_dir "$OUT_DIR" "REMOTE_${host_tag}")"
    log "拉回到本机：$local_pull_dir"
    scp -q -r "${userhost}:${remote_task}/" "$local_pull_dir/"
    log "拉回完成：$local_pull_dir"
  else
    log "未启用 --pull：不拉回"
  fi

  # clean remote if requested
  if [[ "$DO_CLEAN" == "1" ]]; then
    log "清理远端：$remote_work"
    ssh "$userhost" "rm -rf '$remote_work'" >/dev/null || true
  else
    log "未启用 --clean：不清理远端（产物仍在 $remote_out）"
  fi
}

# -------------- main --------------
main() {
  parse_args "$@"

  if [[ "$MODE" == "local" ]]; then
    # local dependencies: ffmpeg/ffprobe + mediainfo always needed if video exists;
    # docker needed only if BDMV exists; we check when processing
    local task_dir
    task_dir="$(process_local_scan "$LOCAL_PATH" "$OUT_DIR")"

    if [[ "$DO_CLEAN" == "1" ]]; then
      # local clean means remove task dir after run (useful for testing)
      log "本地清理：$task_dir"
      rm -rf "$task_dir"
    fi

  elif [[ "$MODE" == "ssh" ]]; then
    run_ssh_mode
  else
    die "MODE 无效"
  fi
}

main "$@"
