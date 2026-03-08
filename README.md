# PT-BDtool

PT-BDtool 是一个“媒体信息打包工具”。  
它会把视频、音频、Blu-ray 原盘目录 `BDMV`、Blu-ray 镜像 `ISO` 处理成一个更适合整理、发帖、保存的结果包。

处理完成后，常见输出大概是这样：
- 视频：`mediainfo.txt` + `1.png` 到 `6.png`
- 音频：`mediainfo.txt` + `频谱图.png`
- 原盘 / ISO：`BDInfo.txt` + `1.png` 到 `6.png`

如果你是第一次接触这个项目，建议直接按下面的 **新手最快上手** 走，不要先自己猜。

## 新手最快上手

### 1）先确认你在哪种环境

最常见的是这两种：

- **本地电脑直接跑**：生成结果后直接保存在你当前电脑
- **VPS / 远程 Linux 跑**：生成结果后先保存在 VPS，再自己下载回来

如果你不确定，先按“本地电脑直接跑”理解即可。

### 2）安装

在项目根目录执行：

```bash
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
```

安装完成后，先检查命令是不是已经可用：

```bash
pt --help
bdtool status
```

如果你看到帮助和状态信息，说明安装基本没问题。

### 3）建议把 PATH 永久写进去

很多新手第一次能用，重开终端后又提示“找不到 pt”。  
这是因为你刚才的 `export PATH=...` 只对当前终端生效。

如果你用的是 `bash`，建议执行：

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

如果你用的是 `zsh`，把上面的 `~/.bashrc` 改成 `~/.zshrc`。

### 4）启动

最简单的启动方式：

```bash
pt
```

说明：
- `pt` / `bdtool`：默认进入菜单模式
- `pt --help` / `bdtool --help`：显示命令帮助

### 5）菜单里怎么走

进入菜单后，按这个顺序走就行：

1. 输入 `1` 开始扫描
2. 选择“全盘扫描”或“扫描指定目录”
3. 等扫描结束
4. 输入你想处理的条目前面的序号
5. 等它自动生成、打包
6. 到提示的结果目录拿包

---

## 最推荐的 3 种用法

### 用法 1：本地电脑直接用

```bash
export PATH="$HOME/.local/bin:$PATH"
pt
```

结果默认保存在当前机器本地。  
如果你的系统能识别桌面目录，通常会优先放在桌面附近的默认结果目录里。

### 用法 2：VPS 上运行，结果先留在 VPS

这是 **最稳、最不容易翻车** 的 VPS 用法：

```bash
export PATH="$HOME/.local/bin:$PATH"
export BDTOOL_DOWNLOAD_DIR="$HOME/PT-BDtool-downloads"
pt
```

处理完成后，结果通常会放到：

```bash
$HOME/PT-BDtool-downloads
```

你再从自己电脑下载：

```bash
scp user@你的VPSIP:$HOME/PT-BDtool-downloads/*.zip .
```

如果打包器没生成 `zip`，也可能是 `tar.gz`。

### 用法 3：不进菜单，直接处理一个文件

如果你已经知道目标文件路径，直接命令模式更快：

```bash
bdtool /path/to/movie.mp4 --out /path/to/output
```

例如：

```bash
bdtool ~/Videos/test.mp4 --out ~/PT-output
```

---

## 真正的启动 / 运行逻辑

这个项目现在的真实使用方式可以简单理解成这样：

- `install.sh`：把程序和离线依赖安装到本机
- `pt` / `bdtool`：默认进菜单模式
- `bdtool <文件或目录>`：直接走命令模式
- `bdtool doctor`：检查依赖
- `bdtool status`：检查安装状态
- `bdtool clean`：清理默认输出目录

也就是说，新手最常用的只有两条：

```bash
bash install.sh --offline
pt
```

---

## VPS 用户推荐写法

如果你是在 VPS 上跑，最推荐先用下面这套，不要一上来折腾自动回传：

```bash
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
export BDTOOL_DOWNLOAD_DIR="$HOME/PT-BDtool-downloads"
pt
```

这样做的好处：
- 不依赖桌面环境
- 不依赖自动上传
- 出问题时更容易定位
- 对新手最友好

---

## 如果你想“处理完自动回传到本地”

这是高级功能。能用，但建议在基础流程跑通后再配。

通过变量 `BDTOOL_RETURN_MODE` 控制：

- `local`：默认模式，结果保存在当前机器
- `http`：处理完成后自动上传到 HTTP 接收端
- `scp`：处理完成后自动通过 `scp` 回传

### 方案 A：HTTP 自动回传

```bash
export BDTOOL_RETURN_MODE=http
export BDTOOL_RETURN_HTTP_URL='http://127.0.0.1:18080/upload'
pt
```

旧变量 `BDTOOL_CLIENT_UPLOAD_URL` 仍然兼容。

### 方案 B：SCP 自动回传

推荐优先使用 SSH 密钥，不建议新手先用密码模式。

```bash
export BDTOOL_RETURN_MODE=scp
export BDTOOL_RETURN_SCP_HOST='127.0.0.1'
export BDTOOL_RETURN_SCP_PORT='10022'
export BDTOOL_RETURN_SCP_USER='your-local-user'
export BDTOOL_RETURN_SCP_REMOTE_DIR='/home/your-local-user/Downloads/PT-BDtool'
export BDTOOL_RETURN_SCP_IDENTITY_FILE="$HOME/.ssh/id_ed25519"
pt
```

可选变量：
- `BDTOOL_RETURN_SCP_PASSWORD`：只有必须密码认证时才用
- `BDTOOL_RETURN_SCP_STRICT_HOST_KEY_CHECKING`：默认 `accept-new`

说明：
- 如果 VPS 访问不到你的本机，要先做好端口映射或反向隧道
- 如果你不确定怎么配，先别开这个功能，先用“结果保存在 VPS”方案

---

## 常用命令

### 查看帮助

```bash
bdtool --help
```

### 检查依赖

```bash
bdtool doctor
```

### 查看安装状态

```bash
bdtool status
```

### 启动菜单

```bash
pt
```

### 清理默认输出目录

```bash
bdtool clean
```

---

## 直接命令示例

### 处理视频

```bash
bdtool /data/movie.mkv --out /data/output
```

### 处理音频

```bash
bdtool /data/song.flac --out /data/output
```

### 处理整个目录

```bash
bdtool /data/media-dir --out /data/output
```

### 只测试流程，不生成截图和 MediaInfo

```bash
bdtool /data/movie.mkv --mode dry --out /data/output
```

### 打开调试日志

```bash
bdtool /data/movie.mkv --log-level debug --out /data/output
```

---

## 常见报错和排查

### 1）提示 `pt: command not found`

通常是 `~/.local/bin` 没在 PATH 里。

先执行：

```bash
export PATH="$HOME/.local/bin:$PATH"
hash -r
pt --help
```

如果这样能好，再把 PATH 写进 `~/.bashrc` 或 `~/.zshrc`。

### 2）提示缺少 `ffmpeg` / `mediainfo` / `BDInfo`

先不要乱装，先直接检查：

```bash
bdtool doctor
```

如果依赖不完整，先回到项目目录重新执行：

```bash
bash install.sh --offline
```

### 3）菜单能打开，但扫不到文件

先确认你输入的是目录，不是某个可执行脚本路径。  
支持的主要类型有：

- 视频：`mkv` `mp4` `m2ts` `ts` `avi` `mov`
- 音频：`mp3` `flac` `wav` `m4a` `aac`
- 蓝光：`BDMV` 目录、`iso` 文件

### 4）VPS 上处理完成后不知道结果在哪

建议你显式指定下载目录：

```bash
export BDTOOL_DOWNLOAD_DIR="$HOME/PT-BDtool-downloads"
pt
```

这样结果就统一在 `$HOME/PT-BDtool-downloads` 里。

---

## 已验证的基本能力

当前仓库里，下面这些流程已经有脚本验证：

- `bdtool --help`
- `bdtool doctor`
- `bdtool status`
- 直接命令模式处理样例视频
- 菜单扫描并生成结果
- VPS 场景下本地保存 / SCP 回传

如果你只是想尽快用起来，照着 README 的安装和启动步骤走即可。

## 结果里通常有什么

### 视频
- `mediainfo.txt`
- `1.png`
- `2.png`
- `3.png`
- `4.png`
- `5.png`
- `6.png`

### 音频
- `mediainfo.txt`
- `频谱图.png`

### 原盘 / ISO
- `BDInfo.txt`
- `1.png`
- `2.png`
- `3.png`
- `4.png`
- `5.png`
- `6.png`

## 卸载

```bash
set -euo pipefail
rm -f "$HOME/.local/bin/bdtool" "$HOME/.local/bin/ptbd-start" "$HOME/.local/bin/pt" "$HOME/.local/bin/pts"
rm -rf "$HOME/.local/share/pt-bdtool/PT-BDtool-app"
rm -f /usr/local/bin/bdtool /usr/local/bin/ptbd-start /usr/local/bin/pt /usr/local/bin/pts 2>/dev/null || true
```
