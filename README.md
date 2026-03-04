# PT-BDtool（极简稳定版）

## 一行安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/My15sir/PT-BDtool/main/install.sh)
```

## 离线依赖与构建

本项目已切换为“构建时准备依赖，运行时离线可用”：
- 构建阶段：`scripts/fetch-deps.sh`
- 打包阶段：`scripts/build-bundle.sh`
- 安装阶段：`bash install.sh --offline`

依赖会整理到：
- `third_party/bundle/linux-amd64/bin`
- `third_party/bundle/linux-amd64/lib`

## 安装（离线优先）

```bash
bash scripts/fetch-deps.sh
bash scripts/build-bundle.sh
bash install.sh --offline
```

说明：
- 安装时不再执行 `apt-get update/install`
- 若离线依赖缺失会直接失败并提示先执行构建脚本

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
bdtool --help
bdtool doctor
bdtool clean
./bdtool.sh --version
bdtool scan
```

## 入口说明

- `bdtool`：安装后的主入口（交互菜单）
- `./bdtool.sh`：兼容脚本入口（CI/自动化更常用）

## 依赖维护策略

- 固定版本：依赖清单位于 `scripts/deps.env`
- SHA 校验：远程下载依赖必须通过 SHA256（`scripts/fetch-deps.sh`）
- 定期更新：建议每月或每季度执行：

```bash
bash scripts/update-deps.sh        # dry-run
bash scripts/update-deps.sh --apply
```

## 测试与工作流

```bash
./full-test.sh
./codex-run.sh
```

说明：
- `codex-run.sh` 默认仅执行测试，不自动提交/推送。
- 如需自动提交与推送：`CODEX_RUN_GIT=1 ./codex-run.sh`

## 仓库清理与目录规范

本仓库已完成一次“瘦身清理”，核心运行文件保持不变：
- `install.sh`
- `bdtool`
- `lib/`
- `README.md`

清理策略：
- 删除运行生成目录与历史产物（如 `bdtool-output/`、历史报告、临时日志）
- 删除本地备份文件（`*.bak`）与不再使用的旧包装脚本
- 保留 `bdtool.sh`，避免影响现有 CI 流程

目录规范（后续提交建议）：
- 源码与脚本：保留在仓库根目录与 `lib/`
- 运行输出：统一写入 `bdtool-output/`（由 `.gitignore` 忽略）
- 临时文件与日志：写入 `tmp/`、`logs/`（由 `.gitignore` 忽略）
