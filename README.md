# PT-BDtool

> 目标：让新手只靠复制粘贴命令完成安装、启动、一次最小跑通和自检。

Language: 中文（本页） | English quick guide: `README.en.md`

## 快速开始（复制即用）

作用：在线拉取仓库并完成离线安装（推荐新手）。
```bash
cd ~
git clone https://github.com/My15sir/PT-BDtool.git
cd PT-BDtool
bash scripts/fetch-deps.sh
bash scripts/build-bundle.sh
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
bdtool --help
```
成功时会看到什么：最后一行输出 `bdtool <path> [options]` 等帮助信息。

## 离线安装（复制即用）

作用：在已拿到离线包 `PT-BDtool-linux-amd64.tar.gz` 的机器上安装。
```bash
cd ~
tar -xzf PT-BDtool-linux-amd64.tar.gz
cd PT-BDtool-linux-amd64
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
bdtool --help
```
成功时会看到什么：安装日志出现 `post-install self-check done: PASS`，随后 `bdtool --help` 正常输出。

## 一键自检命令（复制即用）

作用：快速判断“安装是否完整 + 命令是否可用 + 依赖是否齐全”。
```bash
export PATH="$HOME/.local/bin:$PATH"
set -e
command -v bdtool
command -v ptbd-start
bdtool --help >/dev/null
bdtool doctor
ptbd-start --help >/dev/null
echo "PT-BDtool self-check PASS"
```
成功时会看到什么：最后输出 `PT-BDtool self-check PASS`。
失败判定：命令中任意一步报错即失败，按下方“常见报错一键排查”修复。

## 最小使用流程（从安装到跑通一次）

作用：生成一个可测试视频并让 `bdtool` 完整跑通一次（无需你准备素材）。
```bash
cd ~/PT-BDtool
export PATH="$HOME/.local/bin:$PATH"
ffmpeg -hide_banner -loglevel error -f lavfi -i testsrc=duration=1:size=320x240:rate=24 -c:v libx264 -pix_fmt yuv420p demo.mp4 -y
bdtool ./demo.mp4 --mode dry --out ./bdtool-output/demo-run
find ./bdtool-output/demo-run -type f -name 'README.txt'
```
成功时会看到什么：`find` 能输出 `README.txt` 路径，表示最小流程跑通。

## 卸载/重装（复制即用）

作用：清理旧入口并重装，适用于命令异常、路径残留、版本混乱。
```bash
cd ~/PT-BDtool
set -e
rm -f "$HOME/.local/bin/bdtool" "$HOME/.local/bin/ptbd-start"
rm -rf "$HOME/.local/share/pt-bdtool/PT-BDtool-app"
bash scripts/fetch-deps.sh
bash scripts/build-bundle.sh
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
bdtool --help
```
成功时会看到什么：`bdtool --help` 正常输出，无 `lib/ui.sh` 或函数未定义错误。

## 常见报错一键排查（复制即用）

### 1) 报错：`/usr/local/bin/lib/ui.sh: No such file or directory`
作用：定位旧入口并用离线安装覆盖。
```bash
export PATH="$HOME/.local/bin:$PATH"
command -v bdtool || true
ls -l "$(command -v bdtool)" || true
cd ~/PT-BDtool
bash install.sh --offline
bdtool --help
```
成功时会看到什么：`ls -l` 显示入口指向 PT-BDtool 安装目录，`bdtool --help` 正常。

### 2) 报错：`setup_bundle_runtime/ensure_output_root/section/write_error_file 未定义`
作用：修复不完整安装（通常是旧脚本或目录损坏）。
```bash
cd ~/PT-BDtool
bash scripts/fetch-deps.sh
bash scripts/build-bundle.sh
bash install.sh --offline
bdtool --help
```
成功时会看到什么：安装日志出现 `post-install self-check done: PASS`，帮助命令正常。

### 3) 报错：`bdtool: command not found`
作用：把用户本地 bin 目录加入 PATH。
```bash
export PATH="$HOME/.local/bin:$PATH"
command -v bdtool
bdtool --help
```
成功时会看到什么：`command -v bdtool` 输出路径，帮助命令正常。

### 4) 报错：`offline bundle dependencies are incomplete`
作用：补齐离线依赖后重装。
```bash
cd ~/PT-BDtool
bash scripts/fetch-deps.sh
bash scripts/build-bundle.sh
bash install.sh --offline
```
成功时会看到什么：安装预检查中 `ffmpeg/ffprobe/mediainfo/BDInfo` 均为 `dependency present`。

## 维护者常用命令

作用：发布前跑完整测试。
```bash
cd ~/PT-BDtool
./full-test.sh
```
成功时会看到什么：`FULL TEST RESULT: PASS`。
