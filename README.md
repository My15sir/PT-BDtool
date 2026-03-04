# PT-BDtool

<p><strong>Language / 语言:</strong> <a href="#-中文">中文</a> | <a href="#-english">English</a></p>

---

## 🇨🇳 中文

### 说明
- 不支持 `bash <(curl ... install.sh)` 在线管道安装。
- 必须在本地仓库目录（或离线包解压目录）执行 `install.sh --offline`。

### 首次安装（在线，从零开始，可复制执行）
```bash
cd ~
git clone https://github.com/My15sir/PT-BDtool.git
cd PT-BDtool
bash scripts/fetch-deps.sh
bash scripts/build-bundle.sh
bash install.sh --offline
```

### 首次安装（离线，已具备离线包，可复制执行）
```bash
cd ~
tar -xzf PT-BDtool-linux-amd64.tar.gz
cd PT-BDtool-linux-amd64
bash install.sh --offline
```

### 目录已存在时（更新方式，可复制执行）
```bash
cd ~/PT-BDtool
git pull --ff-only
bash scripts/fetch-deps.sh
bash scripts/build-bundle.sh
bash install.sh --offline
```

### 启动命令（安装后，可复制执行）
```bash
bdtool
ptbd-start
bdtool --help
bdtool doctor
```

### 最小验证流程（可复制执行）
```bash
bdtool --help
bdtool doctor
ptbd-start --help
```

### FAQ（常见问题）

#### 1) `/dev/fd/... offline dependency missing`
你使用了 `bash <(curl ...install.sh)` 或 stdin/fd 方式。  
请改用“先 clone，再本地执行”：
```bash
cd ~/PT-BDtool
bash install.sh --offline
```

#### 2) `scripts/*.sh: No such file or directory`
当前目录不在项目根目录。执行：
```bash
cd ~/PT-BDtool
ls scripts
```

#### 3) `bdtool: command not found`
普通用户安装后请确保 `~/.local/bin` 在 PATH：
```bash
export PATH="$HOME/.local/bin:$PATH"
bdtool --help
```

#### 4) 启动时报 `/usr/local/bin/lib/ui.sh` 或函数未定义
这通常是旧软链/旧安装残留。先查看当前入口：
```bash
command -v bdtool
ls -l "$(command -v bdtool)"
```
然后重新安装：
```bash
cd ~/PT-BDtool
bash install.sh --offline
```

#### 5) 扫描无结果
支持类型：
- 视频：`*.mkv *.mp4 *.avi *.mov *.ts *.m2ts *.wmv *.webm *.mpg *.mpeg`
- 蓝光目录：`BDMV`
- 镜像：`*.iso`

不要输入程序文件路径（例如 `/opt/PT-BDtool/bdtool`），请输入媒体目录。

---

## 🇺🇸 English

### Notes
- `bash <(curl ... install.sh)` is not supported.
- Run `install.sh --offline` from a local repo directory (or extracted offline bundle).

### First-time install (online from scratch, copy-paste)
```bash
cd ~
git clone https://github.com/My15sir/PT-BDtool.git
cd PT-BDtool
bash scripts/fetch-deps.sh
bash scripts/build-bundle.sh
bash install.sh --offline
```

### First-time install (offline bundle already available, copy-paste)
```bash
cd ~
tar -xzf PT-BDtool-linux-amd64.tar.gz
cd PT-BDtool-linux-amd64
bash install.sh --offline
```

### Existing directory update flow (copy-paste)
```bash
cd ~/PT-BDtool
git pull --ff-only
bash scripts/fetch-deps.sh
bash scripts/build-bundle.sh
bash install.sh --offline
```

### Startup commands (after install, copy-paste)
```bash
bdtool
ptbd-start
bdtool --help
bdtool doctor
```

### Minimal verification (copy-paste)
```bash
bdtool --help
bdtool doctor
ptbd-start --help
```

### FAQ

#### 1) `/dev/fd/... offline dependency missing`
You are running installer through fd/stdin (`bash <(curl ...)`).  
Use local repo install:
```bash
cd ~/PT-BDtool
bash install.sh --offline
```

#### 2) `scripts/*.sh: No such file or directory`
You are not in project root:
```bash
cd ~/PT-BDtool
ls scripts
```

#### 3) `bdtool: command not found`
For non-root install, add local bin to PATH:
```bash
export PATH="$HOME/.local/bin:$PATH"
bdtool --help
```

#### 4) Startup shows `/usr/local/bin/lib/ui.sh` or undefined functions
Usually an old symlink/old install issue. Check current entry:
```bash
command -v bdtool
ls -l "$(command -v bdtool)"
```
Then reinstall:
```bash
cd ~/PT-BDtool
bash install.sh --offline
```

#### 5) Scan finds no results
Supported scan types:
- videos: `*.mkv *.mp4 *.avi *.mov *.ts *.m2ts *.wmv *.webm *.mpg *.mpeg`
- Blu-ray directory: `BDMV`
- image: `*.iso`

Do not enter executable path (for example `/opt/PT-BDtool/bdtool`); enter a media directory.
