# FINAL_REPORT

## 本次改动点（对应 A-F）

### A) 菜单选项米黄色（真正生效）
- 在 `lib/ui.sh` 增加菜单颜色检测：
  - 终端支持 256 色：使用 `\033[38;5;223m`
  - 不支持时回退：`\033[0;33m`
- 新增函数 `color_menu_option()`，并在 `bdtool` 菜单渲染中只给选项行着色。
- 保持分级日志颜色不变：`success` 绿色、`error` 红色、`warn` 黄色、`info` 青色。

### B) 菜单项单语显示
- 保留双语字典（`lib/i18n.sh`），菜单渲染只取当前 `LANG_CODE`。
- 菜单项从双语并列改为单语：
  - `zh`：`1) 一键安装`
  - `en`：`1) One-click install`

### C) 交互后屏幕仅一句结果，细节写入日志
- 在 `bdtool` 中统一动作包装器 `run_action()`：
  - 屏幕显示 `section(label)`。
  - 执行过程 stdout/stderr 全部重定向到 `UX_LOG`（`$DATA_DIR/logs/ui.log`）。
  - 成功仅一行：如 `【成功】环境体检已完成` / `Doctor completed`。
  - 失败仅一行：如 `【失败】扫描/生成失败，详情见：.../ui.log`。
  - 然后显示 `按回车返回菜单 / Press Enter to return` 并回菜单。
- 细节（错误堆栈、扫描参数、子命令输出）全部进入 `ui.log`。

### D) 失败不退出菜单
- 菜单循环保持 `while true`，仅在 `7/q/Q` 时退出。
- 子动作失败不会退出菜单主进程；不会掉回 shell。
- 已避免出现 `menu exited with non-zero status` 这类误导提示。

### E) 统一当前语言成功/失败说明
- 成功/失败文案由 `i18n` 的 `t(KEY)` 提供：
  - `ACTION_SUCCESS_PREFIX / ACTION_DONE_SUFFIX`
  - `ACTION_FAIL_PREFIX / ACTION_FAIL_SUFFIX`
- 中文示例：
  - 成功：`【成功】环境体检已完成`
  - 失败：`【失败】扫描/生成失败，详情见：.../ui.log`
- 英文示例：
  - 成功：`Doctor completed`
  - 失败：`Scan failed, see: .../ui.log`

### F) 其他 bug 修复
1. 菜单重绘统一：每轮都使用同一 banner + 框线 + 选项渲染。
2. `logs` 选项：默认 `tail -n 80`，并把完整日志路径写入 `ui.log`。
3. `scan` 不可用时：显示 `扫描功能未实现，已跳过。/ Scan is not available, skipped.`，并回菜单。
4. 路径策略统一：日志目录不再基于 `/usr/local/bin`，改为 `resolve_data_dir()` 可写数据目录策略。

## 菜单颜色实现与 fallback 说明
- 实现位置：`lib/ui.sh`。
- 逻辑：
  - `tput colors >= 256` → 菜单选项使用 `38;5;223`（米黄色）
  - 否则使用 `33`（黄色）
- 人工验证方法：
  - 运行：`printf "7\n" | script -qec './bdtool --lang zh' /dev/null | cat -v`
  - 输出中可见 `^[ [38;5;223m` ANSI 片段即为生效。

## 屏幕输出最小化策略
- 菜单动作执行时：
  - 屏幕只显示阶段标题 + 一句成功/失败 + 返回提示。
  - 详细过程写入：`$DATA_DIR/logs/ui.log`。
- 全局统一运行日志仍追加到：`$DATA_DIR/logs/run.log`。

## 改动文件清单
- `/media/15sir/DataHub/Github/PT-BDtool/lib/ui.sh`
- `/media/15sir/DataHub/Github/PT-BDtool/lib/i18n.sh`
- `/media/15sir/DataHub/Github/PT-BDtool/bdtool`
- `/media/15sir/DataHub/Github/PT-BDtool/FINAL_REPORT.md`

## 复测结果

日志路径：
- `RUN_LOG`: `/home/15sir/.local/share/pt-bdtool/bdtool-output/logs/run.log`
- `UX_LOG`: `/home/15sir/.local/share/pt-bdtool/bdtool-output/logs/ui.log`
- `ux-regression.log`: `/home/15sir/.local/share/pt-bdtool/bdtool-output/logs/ux-regression.log`

| 用例 | 命令 | 结果 | 说明 |
|---|---|---|---|
| 菜单米黄色 ANSI 校验 | `printf "7\n" \| script -qec './bdtool --lang zh' /dev/null \| cat -v` | PASS | 输出包含 `\x1b[38;5;223m` |
| 中文 doctor 一句结果 | `printf "2\n\n7\n" \| ./bdtool --lang zh` | PASS | 动作后仅一行成功说明 |
| 中文 scan 失败不退菜单 | `printf "3\n\n7\n" \| ./bdtool --lang zh` | PASS | 失败后返回菜单，未掉回 shell |
| 中文 logs 后回菜单 | `printf "5\n\n7\n" \| ./bdtool --lang zh` | PASS | tail 后回菜单 |
| 英文 doctor 一句结果 | `printf "2\n\n7\n" \| ./bdtool --lang en` | PASS | `Doctor completed` |

## 回滚命令

```bash
cd /media/15sir/DataHub/Github/PT-BDtool
cp -f lib/ui.sh.bak lib/ui.sh
cp -f lib/i18n.sh.bak lib/i18n.sh
cp -f bdtool.bak bdtool
cp -f FINAL_REPORT.md.bak FINAL_REPORT.md
```

可选 git 回滚：

```bash
cd /media/15sir/DataHub/Github/PT-BDtool
git checkout -- lib/ui.sh lib/i18n.sh bdtool FINAL_REPORT.md
```
