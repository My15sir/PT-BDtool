# PT-BDtool（极简稳定版）

## 一行安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/My15sir/PT-BDtool/main/install.sh)
```

安装流程：
1. 自动检测依赖（已安装会逐项提示；缺失自动安装）
2. 自动安装 `bdtool` 命令入口
3. 自动进入三项主菜单（默认中文）

## 主菜单（严格单语，默认中文）

1. 扫描
2. 切换语言
3. 退出

说明：
- 默认中文，不依赖系统 `LANG`
- 仅 `--lang en`（或 `LANG_CODE=en`）进入英文

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

### 扫描结果选择

- 列出最多前 50 条结果（超出提示“更多已省略”）
- 输入序号选择条目生成产物
- 输入 `0` 返回
- 非法输入最多重试 3 次，超限返回

### 生成产物

输出目录：

```text
$OUTPUT_ROOT/<安全名称>/信息/
```

生成内容：
- 原盘/ISO：`bdinfo.txt`
- 普通视频：`mediainfo.txt`
- 截图固定 6 张：`1.png ... 6.png`

截图说明：
- 如果本机具备 `ffmpeg/ffprobe`，优先尝试真实截图
- 若工具不足或失败，自动使用占位 PNG 并补齐到 6 张

### 下载到本地

生成完成后可选择：
1. 下载结果到本地（打包）
2. 返回菜单

下载目录：

```text
$HOME/Downloads/PT-BDtool/
```

优先 `zip`，否则 `tar.gz`。

### 清理临时文件（安全）

下载后会询问是否清理临时文件：
- 仅清理本次任务产生的临时目录（`$OUTPUT_ROOT/cache/...`）
- 不会删除源视频、原盘目录、ISO 等用户原始文件

## 错误文件（最小化）

默认不写运行日志。仅在错误时生成：

```text
$OUTPUT_ROOT/last_error.txt
```

文件中仅包含简短的错误原因和建议。

## 常用命令

```bash
bdtool
bdtool --lang en
bdtool --help
```
