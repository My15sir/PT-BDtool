# FINAL_REPORT

## 根因分析

1. 菜单失败后掉回 shell 的根因：
- 菜单项执行直接调用 `cmd_scan/cmd_doctor/...`，这些函数内部失败时会 `die`，导致整个 `bdtool` 进程退出。
- 进程退出后用户继续输入 `4/5/6` 就变成 shell 命令，从而出现 `command not found`。

2. 日志路径错到 `/usr/local/bin/bdtool-output` 的根因：
- 旧逻辑把 `BDTOOL_ROOT` 设为入口脚本所在目录；安装后入口位于 `/usr/local/bin` 或 `~/.local/bin`，于是日志目录被拼到该路径下。

## 修复点

### A) 菜单循环“失败不退出”

- 菜单循环保持 `while true`，仅在 `7/q/Q` 时退出。
- 新增 `run_menu_action`：
  - 通过子 shell 执行菜单动作并捕获 `rc`。
  - `rc != 0` 时打印 `error + hint + RUN_LOG`。
  - 无论成功失败都执行 `menu_pause`（按回车返回菜单）。
- 删除/避免菜单层透传非零返回码退出进程。
- 去除安装器里类似 `menu exited with non-zero status` 的告警输出。

### B) 数据目录与日志路径修复

在 `lib/ui.sh` 新增 `resolve_data_dir()` 策略：
1. 若设置 `BDTOOL_DATA_DIR`，优先使用。
2. 若 `/opt/PT-BDtool` 存在且可写（或 root），用 `/opt/PT-BDtool/bdtool-output`。
3. 否则用 `$HOME/.local/share/pt-bdtool/bdtool-output`。
4. 再兜底 `/tmp/pt-bdtool/bdtool-output`。

`ensure_log_dir()` 统一设置：
- `BDTOOL_LOG_DIR="$BDTOOL_DATA_DIR/logs"`
- `BDTOOL_RUN_LOG="$BDTOOL_LOG_DIR/run.log"`

确保日志提示不再出现 `/usr/local/bin/bdtool-output/...`。

### C) 米黄色菜单主题

在 `lib/ui.sh` 新增米黄色：
- 优先 256 色：`\033[38;5;223m`
- fallback：`\033[33m`

新增 `menu_option()` 并用于菜单 1~7 行显示。

### D) install 自动进入菜单

- 仅在交互场景自动跳转（`AUTO_LAUNCH_MENU=1` 且非 `--non-interactive` 且 stdin 为 TTY）。
- 启动命令不再因菜单返回码打印误导性 WARN。

## 改动文件清单

- `/media/15sir/DataHub/Github/PT-BDtool/lib/ui.sh`
- `/media/15sir/DataHub/Github/PT-BDtool/bdtool`
- `/media/15sir/DataHub/Github/PT-BDtool/install.sh`
- `/media/15sir/DataHub/Github/PT-BDtool/FINAL_REPORT.md`

## 备份文件

- `/media/15sir/DataHub/Github/PT-BDtool/lib/ui.sh.bak`
- `/media/15sir/DataHub/Github/PT-BDtool/bdtool.bak`
- `/media/15sir/DataHub/Github/PT-BDtool/install.sh.bak`
- `/media/15sir/DataHub/Github/PT-BDtool/FINAL_REPORT.md.bak`

## 复测结果

日志文件：
- `run.log`: `/home/15sir/.local/share/pt-bdtool/bdtool-output/logs/run.log`
- `menu-loop-test.log`: `/home/15sir/.local/share/pt-bdtool/bdtool-output/logs/menu-loop-test.log`

| 用例 | 命令 | 结果 |
|---|---|---|
| 菜单失败回菜单 | `printf "3\n\n7\n" \| bdtool --lang zh` | PASS（scan 失败后显示 error+hint，回车后返回菜单，再 7 正常退出） |
| 菜单成功回菜单 | `printf "2\n\n7\n" \| bdtool --lang zh` | PASS（doctor 成功后回车返回菜单，再 7 退出） |
| 安装后入口可用 | `env BDTOOL_NO_PROMPT=1 AUTO_LAUNCH_MENU=0 bash ./install.sh` | PASS |

## 回滚命令

```bash
cd /media/15sir/DataHub/Github/PT-BDtool
cp -f lib/ui.sh.bak lib/ui.sh
cp -f bdtool.bak bdtool
cp -f install.sh.bak install.sh
cp -f FINAL_REPORT.md.bak FINAL_REPORT.md
```

可选 git 回滚：

```bash
cd /media/15sir/DataHub/Github/PT-BDtool
git checkout -- lib/ui.sh bdtool install.sh FINAL_REPORT.md
```
