# PT-BDtool（极简稳定版）

## 一行安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/My15sir/PT-BDtool/main/install.sh)
```

## 安装与依赖（稳定机制）

安装时会自动检查依赖：
- `bash/find/awk/sed/sort/timeout/zip/tar/ffmpeg/ffprobe/mediainfo`

行为：
- 已安装：显示 `<依赖> 已安装`
- 未安装：自动安装

apt 稳定性策略：
- `DEBIAN_FRONTEND=noninteractive`
- `apt-get -y`
- 默认 `-qq`（可 `APT_QUIET=0` 关闭）
- 每步超时：`APT_TIMEOUT=300`
- 重试：`APT_RETRY_MAX=3`（退避 1/2/4 秒）
- 锁等待上限：`APT_LOCK_WAIT=60`
- 安装期间每 10 秒输出一次：`仍在安装 <pkg> ...`

当检测到 apt/dpkg 锁占用时：
1. 识别占用进程
2. `kill -TERM` -> 等 5 秒 -> `kill -KILL`
3. 执行 `dpkg --configure -a`
4. 继续安装

`apt-get update` 失败时：
- 不会无限卡住
- 会继续尝试 `install` 一次
- 若仍失败，写 `last_error.txt` 并给一句话提示

## 自举（curl|bash）

远程执行 `install.sh` 且本地缺仓库文件时，自动降级策略：
1. `git clone --depth=1`
2. tarball 下载 + 解压
3. zipball 下载 + unzip

每个策略都带超时与重试，并在失败时给出可操作建议。

## 主菜单（严格单语，默认中文）

仅保留：
1. 扫描
2. 切换语言
3. 退出

## 扫描系统

### 二级菜单
1. 扫描全盘
2. 扫描指定目录
0. 返回

### 扫描规则
- 全盘根目录：`/`
- 默认排除：`/proc /sys /dev /run /tmp`
- 默认 `find -xdev` 防跨挂载（`SCAN_XDEV=0` 可关闭）
- 全盘扫描有二次确认
- 指定目录最多重试 3 次

### 结果展示
- 最多显示 5 条
- 超过 5 条提示：`仅显示前5条，其余已省略`

### 多选
支持输入：
- 单选：`1`
- 多选：`1 2 3`
- 返回：`0`

## 生成产物目录结构

统一保存到：

```text
<OUTPUT_ROOT>/信息/<源文件目录名>/
```

规则：
- 视频：`mediainfo.txt + 1..6.png`
- 原盘/ISO：`bdinfo.txt`
- 视频/ISO：目录名取“父目录名”
- BDMV：目录名取“目录名”
- 目录名安全化：空格->`_`，非法字符去除，长度≤64
- 冲突自动追加 `_2/_3`
- 视频截图不足 6 张时用最后一张补齐

## 下载与清理

生成完成后可选：
1. 下载结果（zip）
2. 返回

下载目录：

```text
~/Downloads/PT-BDtool/
```

下载后可选清理：
- 仅清理本次缓存/临时目录
- 不删除源文件

## 错误文件

默认不写 run.log/ui.log。

仅出错时生成：

```text
<OUTPUT_ROOT>/last_error.txt
```

## 常用命令

```bash
bdtool
bdtool --lang en
bdtool scan
bdtool --help
```
