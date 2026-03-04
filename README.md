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
- 安装前会逐项检查 `ffmpeg/ffprobe/mediainfo/BDInfo` 是否已在离线 bundle 中可执行
- 安装阶段对未变化文件执行“跳过”，并输出 `copied/skipped/elapsed` 统计

## 安装前检查与跳过策略

- 预检查输出：
  - `dependency present: ...` 表示已满足，继续安装
  - `dependency missing: ...` 表示缺失，安装会立即终止并给出修复命令
- 跳过策略：
  - 单文件：源与目标一致时跳过复制
  - 依赖 bundle：目标已有且关键二进制校验一致时跳过整包同步
- 失败提示：
  - 缺失依赖会明确提示执行：`bash scripts/fetch-deps.sh && bash scripts/build-bundle.sh`

## 加速机制 / 缓存机制

- 增量复制：避免每次安装都重复覆盖相同文件
- bundle 缓存命中：关键二进制 SHA 一致时跳过 `bin/lib` 全量复制
- 可量化日志：安装输出包含阶段耗时与总耗时，例如：

```text
[install] precheck done (elapsed=0s)
[install] install stage done (elapsed=1s, copied=3, skipped=5)
[install] total elapsed: 1s
```

## 常见问题：为何某些步骤被跳过？

- 显示 `skip (unchanged)`：表示目标文件与源文件一致，无需重复复制
- 显示 `skip (bundle cached)`：表示离线依赖包已命中缓存，关键二进制未变化
- 这属于预期行为，用于减少安装耗时；若需强制刷新，可先删除安装目录再执行安装

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
