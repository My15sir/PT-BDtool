#!/usr/bin/env bash
set -euo pipefail

# PT-BDtool (bdtool)
# Subcommands:
#   bdtool scan <PATH> --out <DIR>        # local scan
#   bdtool update                         # self-update from GitHub raw
#   bdtool version                        # show version
#   bdtool doctor                         # check dependencies
#
# Backward compatible:
#   bdtool --local PATH --out DIR [--clean]
#   bdtool --ssh user@ip:/path --out DIR [--pull] [--clean]

APP_NAME="bdtool"
REPO_RAW_BASE="https://raw.githubusercontent.com/My15sir/PT-BDtool/main"

die() { echo "[ERROR] $*" >&2; exit 1; }
log() { echo "[$APP_NAME] $*"; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "缺少依赖命令：$1"; }

# ---- utils ----
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
  local dir="$base_out/${ts}__$(safe_name "$label")"
  mkdir -p "$dir"
  echo "$dir"
}

# ---- detection ----
is_bdmv_dir() {
  local bdmv="$1"
  [[ -d "$bdmv/STREAM" && -d "$bdmv/PLAYLIST" ]]
}

find_bdmv_roots() {
  local base="$1"
  find "$base" -type d -name BDMV 2>/dev/null | while read -r d; do
    if is_bdmv_dir "$d"; then
      echo "$d"
    fi
  done | sort -u
}

find_video_files() {
  local base="$1"
  find "$base" -type f \( \
    -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.m2ts" -o -iname "*.ts" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.wmv" -o -iname "*.webm" -o -iname "*.mpg" -o -iname "*.mpeg" \
  \) 2>/dev/null | sort -u
}

# ---- screenshots ----
pick_random_seconds() {
  local duration_s="$1"
  local n="$2"
  local dur_int
  dur_int="${duration_s%.*}"
  [[ -z "$dur_int" || "$dur_int" -lt 1 ]] && dur_int=1

  # avoid first/last 5% if long enough
  local start=0
  local end=$dur_int
  if [[ "$dur_int" -ge 120 ]]; then
    start=$((dur_int / 20))
    end=$((dur_int - dur_int/20))
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

# ---- BDInfo (docker) ----
bdinfo_longest_mpls() {
  local bdroot="$1"
  need_cmd docker
  docker run --rm -i -v "$bdroot":/mnt/bd fr3akyphantom/bdinfocli-ng -l /mnt/bd \
    | awk '$3 ~ /\.MPLS$/ {split($4,t,":"); s=t[1]*3600+t[2]*60+t[3]; if(s>m){m=s; f=$3}} END{print f}'
}

run_bdinfo_report() {
  local bdroot="$1"
  local mpls="$2"
  local outdir="$3"

  need_cmd docker
  mkdir -p "$outdir"

  docker run --rm \
    -v "$bdroot":/mnt/bd \
    -v "$outdir":/mnt/out \
    fr3akyphantom/bdinfocli-ng -m "$mpls" /mnt/bd /mnt/out

  # normalize output name to BDINFO.bd.txt
  local found=""
  found="$(find "$outdir" -maxdepth 1 -type f \( -name "*.bd.txt" -o -name "*.txt" \) | head -n 1 || true)"
  if [[ -n "$found" ]]; then
    mv -f "$found" "$outdir/BDINFO.bd.txt"
  else
    echo "BDInfo 未生成输出文件（请检查 docker/bdinfocli-ng 输出）" > "$outdir/BDINFO.bd.txt"
  fi
}

# ---- MediaInfo ----
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

# ---- process jobs ----
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
  [[ -z "$mpls" ]] && die "未找到 MPLS：$bdroot"
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

  need_cmd find
  need_cmd sort

  mkdir -p "$out_base"
  local task_out
  task_out="$(mk_task_dir "$out_base" "scan_$(safe_name "$scan_path")")"
  log "扫描：$scan_path"
  log "任务目录：$task_out"

  local bdmv_list=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && bdmv_list+=("$line")
  done < <(find_bdmv_roots "$scan_path")

  local video_list=()
  while IFS= read -r vf; do
    [[ -z "$vf" ]] && continue
    [[ "$vf" == *"/BDMV/"* ]] && continue
    video_list+=("$vf")
  done < <(find_video_files "$scan_path")

  if [[ "${#bdmv_list[@]}" -eq 0 && "${#video_list[@]}" -eq 0 ]]; then
    die "未发现 BDMV 或视频文件：$scan_path"
  fi

  if [[ "${#bdmv_list[@]}" -gt 0 ]]; then
    log "发现 BDMV 数量：${#bdmv_list[@]}"
    for b in "${bdmv_list[@]}"; do
      process_bdmv "$b" "$task_out"
    done
  fi

  if [[ "${#video_list[@]}" -gt 0 ]]; then
    log "发现视频文件数量：${#video_list[@]}"
    for v in "${video_list[@]}"; do
      process_video_file "$v" "$task_out"
    done
  fi

  echo "$task_out"
}

# ---- SSH mode (backward compatible) ----
ssh_userhost_and_path() {
  local spec="$1"
  local userhost="${spec%%:*}"
  local path="${spec#*:}"
  echo "$userhost" "$path"
}

run_ssh_mode() {
  local ssh_spec="$1"
  local out_dir="$2"
  local do_pull="$3"
  local do_clean="$4"

  need_cmd ssh
  need_cmd scp

  local userhost remote_path
  read -r userhost remote_path < <(ssh_userhost_and_path "$ssh_spec")
  [[ -n "$userhost" ]] || die "ssh spec 无效：$ssh_spec"
  [[ -n "$remote_path" ]] || die "ssh spec 无效：$ssh_spec"

  local ts remote_work remote_out
  ts="$(date +"%Y%m%d_%H%M%S")"
  remote_work="/tmp/${APP_NAME}_${ts}_$$"
  remote_out="${remote_work}/out"

  log "远程主机：$userhost"
  log "远程扫描：$remote_path"
  log "远程工作目录：$remote_work"

  ssh "$userhost" "mkdir -p '$remote_work' '$remote_out'" >/dev/null
  scp -q "$0" "${userhost}:${remote_work}/bdtool.sh"
  ssh "$userhost" "chmod +x '${remote_work}/bdtool.sh'"

  log "开始远程执行..."
  ssh "$userhost" "'${remote_work}/bdtool.sh' --local '$remote_path' --out '$remote_out'" || die "远程执行失败"

  local remote_task
  remote_task="$(ssh "$userhost" "ls -1dt '$remote_out'/* 2>/dev/null | head -n1" | tr -d '\r' || true)"
  [[ -n "$remote_task" ]] || die "远端未生成任务目录：$remote_out"
  log "远端任务目录：$remote_task"

  if [[ "$do_pull" == "1" ]]; then
    local host_tag local_pull_dir
    host_tag="$(echo "$userhost" | sed 's/@/_/g; s/[^A-Za-z0-9._-]/_/g')"
    local_pull_dir="$(mk_task_dir "$out_dir" "REMOTE_${host_tag}")"
    log "拉回到本机：$local_pull_dir"
    scp -q -r "${userhost}:${remote_task}/" "$local_pull_dir/"
    log "拉回完成：$local_pull_dir"
  else
    log "未启用 --pull：不拉回"
  fi

  if [[ "$do_clean" == "1" ]]; then
    log "清理远端：$remote_work"
    ssh "$userhost" "rm -rf '$remote_work'" >/dev/null || true
  else
    log "未启用 --clean：不清理远端（产物仍在 $remote_out）"
  fi
}

# ---- subcommands ----
cmd_version() {
  # lightweight "version": show current commit if available; fallback to date
  if need_cmd git && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local v
    v="$(git rev-parse --short HEAD 2>/dev/null || true)"
    [[ -n "$v" ]] && { echo "$APP_NAME $v"; return 0; }
  fi
  echo "$APP_NAME $(date +%Y%m%d)"
}

cmd_doctor() {
  echo "== doctor =="
  for c in find sort od awk sed; do
    command -v "$c" >/dev/null 2>&1 && echo "OK: $c" || echo "MISS: $c"
  done
  for c in ffmpeg ffprobe mediainfo docker ssh scp wget curl; do
    command -v "$c" >/dev/null 2>&1 && echo "OK: $c" || echo "MISS: $c"
  done
  echo "提示：缺什么就用 install.sh -k 自动装（或手动装）。"
}

cmd_update() {
  # Update target: prefer "bdtool" command path if exists, else update current script path.
  local target=""
  if command -v bdtool >/dev/null 2>&1; then
    target="$(command -v bdtool)"
  else
    target="$0"
  fi

  local url="${REPO_RAW_BASE}/bdtool.sh"

  local tmp
  tmp="$(mktemp -t bdtool.XXXXXX)"
  trap 'rm -f "$tmp"' EXIT

  if command -v wget >/dev/null 2>&1; then
    wget -qO "$tmp" "$url" || die "下载失败：$url"
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$tmp" || die "下载失败：$url"
  else
    die "需要 wget 或 curl 才能 update"
  fi

  # sanity check
  head -n 1 "$tmp" | grep -q "#!/usr/bin/env bash" || die "下载内容不像脚本（拒绝覆盖）"

  # install
  if [[ -w "$target" ]]; then
    cp -f "$tmp" "$target"
    chmod +x "$target"
    echo "updated: $target"
  else
    # fallback to user bin
    mkdir -p "$HOME/bin"
    cp -f "$tmp" "$HOME/bin/bdtool"
    chmod +x "$HOME/bin/bdtool"
    echo "updated: $HOME/bin/bdtool"
    echo "提示：当前目标不可写，已更新到 ~/bin/bdtool"
  fi
}

cmd_scan() {
  local scan_path=""
  local out_dir=""

  # parse: scan <PATH> --out <DIR>
  if [[ $# -lt 1 ]]; then
    die "用法：bdtool scan <PATH> --out <DIR>"
  fi
  scan_path="$1"; shift 1

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --out) out_dir="${2:-}"; shift 2;;
      *) die "未知参数：$1";;
    esac
  done

  [[ -d "$scan_path" ]] || die "路径不存在：$scan_path"
  [[ -n "$out_dir" ]] || die "缺少 --out"
  mkdir -p "$out_dir"

  process_local_scan "$scan_path" "$out_dir" >/dev/null
}

# ---- legacy args ----
legacy_usage() {
  cat <<USAGE
用法（推荐新命令）：
  bdtool scan <PATH> --out <DIR>
  bdtool update
  bdtool version
  bdtool doctor

兼容旧用法：
  bdtool --local PATH --out DIR [--clean]
  bdtool --ssh user@ip:/path --out DIR [--pull] [--clean]
USAGE
}

main_legacy() {
  local DO_PULL="0"
  local DO_CLEAN="0"
  local MODE=""
  local LOCAL_PATH=""
  local SSH_SPEC=""
  local OUT_DIR=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --local) MODE="local"; LOCAL_PATH="${2:-}"; shift 2;;
      --ssh)   MODE="ssh"; SSH_SPEC="${2:-}"; shift 2;;
      --out)   OUT_DIR="${2:-}"; shift 2;;
      --pull)  DO_PULL="1"; shift 1;;
      --clean) DO_CLEAN="1"; shift 1;;
      -h|--help) legacy_usage; exit 0;;
      *) die "未知参数：$1";;
    esac
  done

  [[ -n "$MODE" ]] || die "缺少 --local 或 --ssh"
  [[ -n "$OUT_DIR" ]] || die "缺少 --out"
  mkdir -p "$OUT_DIR"

  if [[ "$MODE" == "local" ]]; then
    [[ -d "$LOCAL_PATH" ]] || die "本地路径不存在：$LOCAL_PATH"
    local task_dir
    task_dir="$(process_local_scan "$LOCAL_PATH" "$OUT_DIR")"
    if [[ "$DO_CLEAN" == "1" ]]; then
      log "本地清理：$task_dir"
      rm -rf "$task_dir"
    fi
  else
    run_ssh_mode "$SSH_SPEC" "$OUT_DIR" "$DO_PULL" "$DO_CLEAN"
  fi
}

main() {
  if [[ $# -eq 0 ]]; then
    legacy_usage
    exit 0
  fi

  case "$1" in
    scan) shift; cmd_scan "$@";;
    update) shift; cmd_update;;
    version) shift; cmd_version;;
    doctor) shift; cmd_doctor;;
    --local|--ssh|--out|--pull|--clean|-h|--help) main_legacy "$@";;
    *) legacy_usage; die "未知命令：$1";;
  esac
}

main "$@"
