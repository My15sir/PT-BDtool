# PT-BDtool

PT 上传素材生成工具（Bash）。  
PT upload material generator (Bash).

## Quick Start（快速开始）

### CN
- 本项目现在是**纯离线安装流程**：先在本地仓库准备依赖，再执行安装。
- 不再支持在线一键安装（`bash <(curl ... install.sh)`）。

### EN
- This project now uses an **offline-only install flow**: prepare dependencies in a local repo, then install.
- Online one-liner install (`bash <(curl ... install.sh)`) is no longer supported.

## Offline Install Only（仅支持离线安装）

### CN
旧方式已废弃（不要再用）：
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/My15sir/PT-BDtool/main/install.sh)
```
上面命令会在 `/dev/fd` 场景失败，这是预期保护行为。

### EN
Deprecated method (do not use):
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/My15sir/PT-BDtool/main/install.sh)
```
This fails by design in `/dev/fd` mode to prevent broken offline installs.

## Copy-Paste Commands（可直接复制执行）

### A) 普通用户 / Normal user
```bash
cd ~
git clone https://github.com/My15sir/PT-BDtool.git
cd PT-BDtool
bash scripts/fetch-deps.sh
bash scripts/build-bundle.sh
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
bdtool
```

### B) VPS/root（有 sudo）/ VPS or root (with sudo)
```bash
cd /opt
sudo git clone https://github.com/My15sir/PT-BDtool.git
cd PT-BDtool
sudo bash scripts/fetch-deps.sh
sudo bash scripts/build-bundle.sh
sudo bash install.sh --offline
bdtool
```

说明 / Notes:
- CN：普通用户默认安装到 `~/.local/share/pt-bdtool/PT-BDtool-app`，命令软链到 `~/.local/bin`。
- EN: Non-root install target is `~/.local/share/pt-bdtool/PT-BDtool-app`, with symlink in `~/.local/bin`.
- CN：root/sudo 安装默认落到 `/opt/PT-BDtool`，命令软链到 `/usr/local/bin`。
- EN: root/sudo install target is `/opt/PT-BDtool`, with symlink in `/usr/local/bin`.

## Minimal Newbie Path（新手最小路径）

### CN
1. 打开终端，先执行 `cd ~`。  
2. 克隆仓库：`git clone ...`。  
3. 进入目录：`cd PT-BDtool`。  
4. 依次执行：`fetch-deps -> build-bundle -> install --offline`。  
5. 执行 `bdtool` 启动。  

### EN
1. Open terminal and run `cd ~` first.  
2. Clone the repo: `git clone ...`.  
3. Enter project folder: `cd PT-BDtool`.  
4. Run in order: `fetch-deps -> build-bundle -> install --offline`.  
5. Start with `bdtool`.  

## Troubleshooting（常见报错排查）

### 1) `/dev/fd/... offline dependency missing`
CN：你使用了 `bash <(curl ...)` 或 stdin/fd 方式运行安装脚本。请改为“先克隆仓库，再在本地目录执行 `bash install.sh --offline`”。  
EN: You ran installer via `bash <(curl ...)` or fd/stdin mode. Use local repo install: clone first, then run `bash install.sh --offline`.

### 2) `scripts/*.sh: No such file or directory`
CN：当前目录不在仓库根目录。先执行：
```bash
cd ~/PT-BDtool
ls scripts
```
确认存在 `fetch-deps.sh`、`build-bundle.sh` 后再执行。  
EN: You are not in project root. Run:
```bash
cd ~/PT-BDtool
ls scripts
```
Make sure `fetch-deps.sh` and `build-bundle.sh` exist, then rerun.

### 3) `bdtool: command not found`
CN：安装后 PATH 里没有 `~/.local/bin`（普通用户场景）。执行：
```bash
export PATH="$HOME/.local/bin:$PATH"
bdtool --help
```
EN: `~/.local/bin` is not in PATH (non-root install). Run:
```bash
export PATH="$HOME/.local/bin:$PATH"
bdtool --help
```

### 4) 启动异常或扫描无结果 / startup works but scan returns nothing
CN：
- 若 `bdtool` 启动异常，可先用 `ptbd-start` 兜底：
```bash
ptbd-start
```
- 若提示“未发现可处理条目”，请确认扫描目录中包含以下类型：
  - 视频：`*.mkv *.mp4 *.avi *.mov *.ts *.m2ts *.wmv *.webm *.mpg *.mpeg`
  - 蓝光：`BDMV` 目录
  - 镜像：`*.iso`
- 如果你输入了 `/opt/PT-BDtool/bdtool` 这类程序文件路径，请改为媒体目录，例如：
```bash
/home/<user>/Downloads
```
EN:
- If `bdtool` startup is abnormal, try fallback:
```bash
ptbd-start
```
- If you get "No items found", ensure the target directory contains:
  - Videos: `*.mkv *.mp4 *.avi *.mov *.ts *.m2ts *.wmv *.webm *.mpg *.mpeg`
  - Blu-ray: `BDMV` folder
  - Images: `*.iso`
- If you entered a program path such as `/opt/PT-BDtool/bdtool`, use a media directory instead, for example:
```bash
/home/<user>/Downloads
```

## Verify Installation（安装验证）

### CN
```bash
bdtool --help
bdtool doctor
```
期望看到帮助信息与依赖检查结果。

### EN
```bash
bdtool --help
bdtool doctor
```
Expected: help output and dependency check result.

## Install Precheck / Skip Behavior（安装预检查与跳过策略）

### CN
- 预检查会输出 `dependency present` / `dependency missing`。
- 未变化文件会输出 `skip (unchanged)`。
- 依赖包命中缓存会输出 `skip (bundle cached)`。
- 缺失依赖时会明确提示执行：
  `bash scripts/fetch-deps.sh && bash scripts/build-bundle.sh`

### EN
- Precheck prints `dependency present` / `dependency missing`.
- Unchanged files print `skip (unchanged)`.
- Cached dependency bundle prints `skip (bundle cached)`.
- If dependencies are missing, installer prints:
  `bash scripts/fetch-deps.sh && bash scripts/build-bundle.sh`

## Entrypoints（入口）

### CN
- `bdtool`：安装后的主入口。
- `./bdtool.sh`：兼容脚本入口（CI/自动化常用）。

### EN
- `bdtool`: main command after install.
- `./bdtool.sh`: compatibility entry for CI/automation.

## Dependency Maintenance（依赖维护）

### CN
```bash
bash scripts/update-deps.sh
bash scripts/update-deps.sh --apply
```

### EN
```bash
bash scripts/update-deps.sh
bash scripts/update-deps.sh --apply
```
