# PT-BDtool

> 目标：让新手只靠复制粘贴命令完成安装、启动、一次最小跑通和自检（失败即停）。

Language: 中文（本页） | English quick guide: `README.en.md`

## 快速开始（复制即用，失败即停）

作用：在线拉取或更新仓库并直接安装；目录已存在时自动走更新。
```bash
set -euo pipefail
cd ~
if [ -d PT-BDtool/.git ]; then
  cd PT-BDtool
  git pull --ff-only
else
  git clone https://github.com/My15sir/PT-BDtool.git
  cd PT-BDtool
fi
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
bdtool --help
pt --help
pts --help
```
成功时会看到什么：最后输出 `用法: bdtool [--lang zh|en]` 或 `bdtool <path> [options]`。

## 离线安装（复制即用，失败即停）

作用：使用官方离线包安装；若离线包不存在会立即停止。
```bash
set -euo pipefail
cd ~
test -f PT-BDtool-linux-amd64.tar.gz
tar -xzf PT-BDtool-linux-amd64.tar.gz
cd PT-BDtool-linux-amd64
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
bdtool --help
```
成功时会看到什么：安装日志出现 `post-install self-check done: PASS`。

## 一键自检命令（复制即用）

作用：检查入口、帮助命令和依赖是否完整。
```bash
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
command -v bdtool
command -v ptbd-start
command -v pt
command -v pts
bdtool --help >/dev/null
bdtool doctor
ptbd-start --help >/dev/null
pt --help >/dev/null
pts --help >/dev/null
echo "PT-BDtool self-check PASS (bdtool/ptbd-start/pt/pts)"
```
成功时会看到什么：最后输出 `PT-BDtool self-check PASS (bdtool/ptbd-start/pt/pts)`。

## 最小使用流程（安装后跑通一次）

作用：自动生成样本视频并执行一次 dry 模式处理。
```bash
set -euo pipefail
cd ~/PT-BDtool
export PATH="$HOME/.local/bin:$PATH"
ffmpeg -hide_banner -loglevel error -f lavfi -i testsrc=duration=1:size=320x240:rate=24 -c:v libx264 -pix_fmt yuv420p demo.mp4 -y
bdtool ./demo.mp4 --mode dry --out ./bdtool-output/demo-run
find ./bdtool-output/demo-run -type f -name 'README.txt'
```
成功时会看到什么：`find` 输出一条 `README.txt` 路径。

## 音乐文件生成频谱图（复制即用）

作用：使用音频输入直接生成 `频谱图_1.png` 与 `mediainfo_1.txt`。
```bash
set -euo pipefail
cd ~/PT-BDtool
export PATH="$HOME/.local/bin:$PATH"
mkdir -p ./bdtool-output/audio-demo
ffmpeg -hide_banner -loglevel error -y -f lavfi -i "sine=frequency=1000:duration=8" ./demo-audio.wav
bdtool ./demo-audio.wav --out ./bdtool-output/audio-demo
info_dir="$(find ./bdtool-output/audio-demo -type d -name 信息 | head -n 1)"
test -s "$info_dir/频谱图_1.png"
test -s "$info_dir/mediainfo_1.txt"
find "$info_dir" -maxdepth 1 -type f -printf '%f\n' | sort
```
成功时会看到什么：输出中包含 `频谱图_1.png` 与 `mediainfo_1.txt`，且二者非空。

## 常见报错一键排查（复制即用）

### 1) `/usr/local/bin/lib/ui.sh: No such file or directory`
作用：清理旧入口残留并重装。
```bash
set -euo pipefail
cd ~/PT-BDtool
rm -f /usr/local/bin/bdtool /usr/local/bin/ptbd-start 2>/dev/null || true
rm -f "$HOME/.local/bin/bdtool" "$HOME/.local/bin/ptbd-start"
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
bdtool --help
```
成功时会看到什么：`bdtool --help` 正常输出，不再报 `lib/ui.sh`。

### 2) `setup_bundle_runtime / ensure_output_root / section / write_error_file: command not found`
作用：修复旧脚本或不完整安装导致的函数缺失。
```bash
set -euo pipefail
cd ~/PT-BDtool
rm -f /usr/local/bin/bdtool /usr/local/bin/ptbd-start 2>/dev/null || true
rm -f "$HOME/.local/bin/bdtool" "$HOME/.local/bin/ptbd-start"
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
bdtool --help
```
成功时会看到什么：安装日志出现 `post-install self-check done: PASS`。

### 3) `processing ffmpeg version=system` + `ffmpeg not found in PATH`
作用：明确 `PTBD_FETCH_MODE` 分支并给出可复制修复。
```bash
set -euo pipefail
cd ~/PT-BDtool

# A) 推荐：system 模式（当前默认 deps.env 就是 system://）
PTBD_FETCH_MODE=system bash scripts/fetch-deps.sh

# B) 仅当你的 deps.env 改成 http(s) URL 时才用 remote 模式
# PTBD_FETCH_MODE=remote bash scripts/fetch-deps.sh
```
成功时会看到什么：`summary: success=... fail=0`。
失败处理：若系统没有依赖，优先使用官方离线包；或先安装系统依赖后再执行 system 模式。

### 4) `git clone ... already exists`
作用：避免旧目录残留导致流程继续执行。
```bash
set -euo pipefail
cd ~
if [ -d PT-BDtool/.git ]; then
  cd PT-BDtool && git pull --ff-only
else
  git clone https://github.com/My15sir/PT-BDtool.git
  cd PT-BDtool
fi
bash install.sh --offline
```
成功时会看到什么：仓库更新或克隆成功后继续安装。

### 5) `PT-BDtool-linux-amd64.tar.gz: No such file or directory`
作用：离线安装前先硬性检查包文件存在。
```bash
set -euo pipefail
cd ~
test -f PT-BDtool-linux-amd64.tar.gz
tar -xzf PT-BDtool-linux-amd64.tar.gz
```
成功时会看到什么：`tar` 正常解压，不会出现 `Cannot open`。

## 维护者验证

作用：发布前执行完整回归。
```bash
set -euo pipefail
cd ~/PT-BDtool
./full-test.sh
```
成功时会看到什么：`FULL TEST RESULT: PASS`。
