# FINAL_REPORT

## 本次重构目标达成

- `bash <(curl -fsSL .../install.sh)` 入口改为“优先进入 1-7 主菜单”（交互终端下）
- 默认中文，严格单语
- 增加系统级稳定机制：全局 trap、互斥锁、超时、资源保护、DATA_DIR 约束
- 扫描系统升级：全盘/指定/后台、任务状态、停止、恢复、断点续扫、进度显示
- 清理系统升级：manifest 白名单删除、路径边界校验、默认 dry-run

## 关键架构实现

### 1) 安装入口即菜单
- `install.sh` 在交互终端且无参数时直接 `exec ./bdtool --lang zh`。
- 非交互时默认走 `bdtool install --non-interactive --lang zh`。
- 自举模式（curl|bash 无仓库文件）保留：自动拉取完整仓库后继续执行。

### 2) 全局安全机制
- 全局 trap：`ERR/INT/TERM` 均写入日志。
- 互斥锁：`$DATA_DIR/state/lock`，防止并发任务。
- 外部命令统一通过 `timeout`（默认 300 秒）。
- 扫描最大时长：`PTBD_SCAN_MAX_SECONDS`（默认 300 秒）。
- 资源保护：扫描执行使用 `nice` + `ionice`（可用时自动启用）。

### 3) 生产级扫描系统
- 扫描二级菜单：
  1. 扫描全盘
  2. 扫描指定目录
  3. 后台扫描
  0. 返回
- 全盘扫描含三条风险提示，要求输入 `1` 才继续。
- 后台扫描支持：
  - 启动后台任务
  - 查看任务状态
  - 停止任务
  - 恢复扫描
- 任务状态文件：`$DATA_DIR/state/tasks/<task_id>.json`
- 断点续扫：`$DATA_DIR/state/progress.db`
- TTY 下显示计数进度条；非 TTY 仅写日志。

### 4) 大盘优化与识别规则
- 扫描排除：`/proc /sys /dev /run /tmp`
- 默认 `find -xdev`（可通过 `PTBD_SCAN_XDEV=0` 关闭）
- inode 优化排序（可通过 `PTBD_INODE_OPT=0` 关闭）
- 识别规则：
  - 普通视频：`mkv/mp4/avi/mov/ts/m2ts/wmv/webm/mpg/mpeg`
  - 原盘：`BDMV` 目录、`.iso`

### 5) 输出归档规范
- 每条扫描条目写入：`$DATA_DIR/output/<安全名>/信息/`
- 信息文件：`mediainfo.txt` 或 `bdinfo.txt`
- 截图固定 `1.png` 到 `6.png`，不足自动补齐复制（无源则创建占位）
- 总报告：`$DATA_DIR/output/REPORT.md`

### 6) 清理机制（绝对安全）
- manifest 文件：`$DATA_DIR/state/manifest.txt`
- 默认 dry-run，不实际删除
- 真删必须二次确认（交互模式）
- 仅允许删除 `manifest` 中且位于 `$DATA_DIR` 内的路径

### 7) DATA_DIR 规则
- 优先：`/opt/PT-BDtool/bdtool-output`（可写或 root）
- 否则：`$HOME/.local/share/pt-bdtool/bdtool-output`
- 再兜底：`/tmp/pt-bdtool/bdtool-output`
- 不使用 `/usr/local/bin` 作为数据目录

### 8) UI 规则落地
- 默认中文（不依赖系统 LANG）
- 严格单语（当前语言输出）
- 菜单选项米黄色：
  - 256 色：`38;5;223`
  - fallback：`33`
- 屏幕不刷 `[INFO]` 前缀，失败不退出菜单

### 9) 日志系统
- `RUN_LOG`: `$DATA_DIR/logs/run.log`
- `UI_LOG`: `$DATA_DIR/logs/ui.log`
- `REG_LOG`: `$DATA_DIR/logs/ux-regression.log`
- 任务元数据：`$DATA_DIR/state/tasks/*.json`

## 改动文件清单
- `/media/15sir/DataHub/Github/PT-BDtool/install.sh`
- `/media/15sir/DataHub/Github/PT-BDtool/bdtool`
- `/media/15sir/DataHub/Github/PT-BDtool/lib/i18n.sh`
- `/media/15sir/DataHub/Github/PT-BDtool/FINAL_REPORT.md`

## 复测结果（真实执行）

日志：`/home/15sir/.local/share/pt-bdtool/bdtool-output/logs/ux-regression.log`

| 用例 | 命令 | 结果 |
|---|---|---|
| install 启动显示菜单 | `script -qec 'bash ./install.sh' /dev/null <<< '7'` | PASS |
| 扫描全盘风险提示 | `printf "3\n1\n0\n7\n" \| ./bdtool` | PASS |
| 指定目录扫描 | `printf "3\n2\n/media/15sir/DataHub/Github/PT-BDtool\n\n7\n" \| ./bdtool` | PASS |
| 后台扫描启动 | `printf "3\n3\n1\n/media/15sir/DataHub/Github/PT-BDtool\n\n0\n0\n7\n" \| ./bdtool` | PASS |
| clean dry-run | `printf "4\n7\n" \| ./bdtool` | PASS |
| 断点续扫模拟 | `./bdtool scan /media/15sir/DataHub/Github/PT-BDtool --resume` | PASS |
| 默认中文无英文泄露 | `printf "7\n" \| ./bdtool | grep -Eq 'One-click|Doctor|Quit|Version'` | PASS |

## 回滚命令

```bash
cd /media/15sir/DataHub/Github/PT-BDtool
cp -f install.sh.bak install.sh
cp -f bdtool.bak bdtool
cp -f lib/i18n.sh.bak lib/i18n.sh
cp -f FINAL_REPORT.md.bak FINAL_REPORT.md
```

可选 git 回滚：

```bash
cd /media/15sir/DataHub/Github/PT-BDtool
git checkout -- install.sh bdtool lib/i18n.sh FINAL_REPORT.md
```
