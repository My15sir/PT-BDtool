# PT-BDtool（极简稳定版）

## 一行安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/My15sir/PT-BDtool/main/install.sh)
```

## 依赖安装稳定性（本次修复）

安装脚本依赖阶段已改为“无人值守 + 可控超时 + 自动重试”：
- `DEBIAN_FRONTEND=noninteractive`
- `apt-get -y`（自动确认）
- 默认低噪音：`-qq`（可通过 `APT_QUIET=0` 关闭）
- 每个 apt 子步骤超时：`APT_TIMEOUT`（默认 `300` 秒）
- 每步最多重试 `APT_RETRY_MAX` 次（默认 `3`，退避 `1/2/4` 秒）
- apt/dpkg 锁等待上限：`APT_LOCK_WAIT`（默认 `60` 秒）

当检测到锁占用超时，会明确提示：
- “有其他 apt 进程占用”
- 建议检查 `unattended-upgrades`/其他 apt 任务

### 依赖安装排障命令

```bash
# 查看 apt/dpkg 进程
ps -ef | egrep 'apt|apt-get|dpkg|unattended' | grep -v grep

# 查看锁文件占用（若已安装 lsof/fuser）
lsof /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock /var/cache/apt/archives/lock
fuser /var/lib/dpkg/lock-frontend

# 验证源可用性
apt-get update
```

## 自举策略（curl|bash 场景）

当直接执行远程 `install.sh` 且本地没有仓库文件时，会自动按顺序自举：
1. `git clone --depth=1`
2. 下载 tarball 并解压
3. 下载 zipball 并解压

每个策略均为：
- 单次 300 秒超时
- 最多 3 次重试
- 指数退避 1s / 2s / 4s

失败时会输出具体原因与建议（DNS/TLS/403/404/超时/命令缺失），并给出调试日志路径。

### 自举失败排查（可复制命令）

```bash
# 1) 检查 DNS
cat /etc/resolv.conf

# 2) 安装证书与下载工具（Debian/Ubuntu）
apt-get update && apt-get install -y ca-certificates git curl wget tar unzip

# 3) 离线方案
git clone https://github.com/My15sir/PT-BDtool.git && cd PT-BDtool && bash install.sh
```

## 主菜单（严格单语，默认中文）

1. 扫描
2. 切换语言
3. 退出

## 扫描闭环

### 扫描二级菜单

1. 扫描全盘（需二次确认）
2. 扫描指定目录（输入目录并校验）
0. 返回

### 识别规则

- 普通视频：`mkv/mp4/avi/mov/ts/m2ts/wmv/webm/mpg/mpeg`
- 原盘目录：目录内存在 `BDMV/`
- ISO：`*.iso`
- 默认排除：`/proc /sys /dev /run /tmp`

### 生成产物

输出目录：

```text
$OUTPUT_ROOT/<安全名称>/信息/
```

生成内容：
- 原盘/ISO：`bdinfo.txt`
- 普通视频：`mediainfo.txt`
- 截图固定 6 张：`1.png ... 6.png`

### 下载到本地

下载目录：

```text
$HOME/Downloads/PT-BDtool/
```

优先 `zip`，否则 `tar.gz`。

## 错误文件（最小化）

仅在错误时生成：

```text
$OUTPUT_ROOT/last_error.txt
```

## 常用命令

```bash
bdtool
bdtool --lang en
bdtool --help
```
