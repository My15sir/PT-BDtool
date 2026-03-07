# PT-BDtool

PT-BDtool 是一个“媒体信息打包工具”。

它可以处理：
- 视频文件
- 音频文件
- Blu-ray 原盘目录 `BDMV`
- Blu-ray 镜像 `ISO`

处理完成后，它会自动生成适合整理/发布使用的信息包，例如：
- 视频：`mediainfo.txt` + `1.png` 到 `6.png`
- 音频：`mediainfo.txt` + `频谱图.png`
- 原盘：`BDInfo.txt` + `1.png` 到 `6.png`

如果你只想知道“怎么用”，直接看下面的 **3 分钟上手**。

## 3 分钟上手

### 第一步：安装
在项目目录里执行：

```bash
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
```

检查是否安装成功：

```bash
pt --help
```

### 第二步：启动
最简单的启动方式：

```bash
pt
```

### 第三步：照着菜单走
进入菜单后：

1. 输入 `1` 开始扫描
2. 等扫描完成
3. 输入你想处理的条目前面的序号
4. 等它自动生成、打包
5. 到提示的目录里拿结果

## 最常见的 3 种用法

### 用法 1：本地电脑直接用
如果你是在自己电脑上用，最简单：

```bash
export PATH="$HOME/.local/bin:$PATH"
pt
```

结果默认会放到你的桌面目录里。

### 用法 2：VPS 上使用，结果先保存在 VPS
如果你是在 VPS 上跑，最简单也最稳的用法是：

```bash
export PATH="$HOME/.local/bin:$PATH"
export BDTOOL_DOWNLOAD_DIR="$HOME/PT-BDtool-downloads"
pt
```

处理完成后，结果会放到：

```bash
$HOME/PT-BDtool-downloads
```

然后你在本地电脑执行下载：

```bash
scp user@你的VPSIP:$HOME/PT-BDtool-downloads/*.zip .
```

如果不是 zip，也可能是 `tar.gz`。

### 用法 3：不想走菜单，直接处理单个文件
如果你已经知道文件路径，直接用命令更简单：

```bash
bdtool /path/to/movie.mp4 --out /path/to/output
```

例如：

```bash
bdtool ~/Videos/test.mp4 --out ~/PT-output
```

## VPS 用户最推荐的写法

如果你是 VPS 用户，我推荐优先用下面这套：

```bash
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
export BDTOOL_DOWNLOAD_DIR="$HOME/PT-BDtool-downloads"
pt
```

这样做的好处：
- 不依赖桌面环境
- 不依赖自动回传
- 不容易出错
- 出问题时也容易排查

## 如果你想“处理完自动回传到本地”

这是高级功能，但现在已经正式支持。

通过变量 `BDTOOL_RETURN_MODE` 控制，有 3 种模式：

- `local`：默认模式，保存到当前机器本地
- `http`：处理完成后自动上传到你的 HTTP 接收端
- `scp`：处理完成后自动通过 `scp` 传回你的目标机器

### 方案 A：HTTP 自动回传
适合你已经有接收服务，或者你会用反向隧道。

```bash
export BDTOOL_RETURN_MODE=http
export BDTOOL_RETURN_HTTP_URL='http://127.0.0.1:18080/upload'
pt
```

兼容旧变量：

```bash
BDTOOL_CLIENT_UPLOAD_URL
```

也仍然可用。

### 方案 B：SCP 自动回传
推荐使用 SSH 密钥认证。

```bash
export BDTOOL_RETURN_MODE=scp
export BDTOOL_RETURN_SCP_HOST='127.0.0.1'
export BDTOOL_RETURN_SCP_PORT='10022'
export BDTOOL_RETURN_SCP_USER='your-local-user'
export BDTOOL_RETURN_SCP_REMOTE_DIR='/home/your-local-user/Downloads/PT-BDtool'
export BDTOOL_RETURN_SCP_IDENTITY_FILE="$HOME/.ssh/id_ed25519"
pt
```

可选项：
- `BDTOOL_RETURN_SCP_PASSWORD`：必须用密码时可设置；程序会尝试用 `sshpass -e`
- `BDTOOL_RETURN_SCP_STRICT_HOST_KEY_CHECKING`：默认 `accept-new`

说明：
- 如果 VPS 不能直接访问你的本机，请先做好反向隧道
- 如果你不确定怎么配，建议先用前面那个“结果先保存在 VPS”方案

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

### 清理输出目录
```bash
bdtool clean
```

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

## 菜单模式会做什么

你执行 `pt` 后，程序大致会这样工作：

1. 扫描媒体文件
2. 列出候选条目
3. 你输入序号
4. 自动生成信息文件和截图
5. 自动打包
6. 自动保存或自动回传
7. 默认自动清理本次生成目录

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
