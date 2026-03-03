# FINAL_REPORT

## 修复概览

本次按最新验收要求重构了交互控制台：
- 新增扫描/生成子菜单（目录数字选择）
- 默认中文（仅显式 `--lang en` 或 `LANG_CODE=en` 时进入英文）
- 严格单语渲染（菜单/提示/成功失败文案均按当前语言输出）
- 默认隐藏 `[INFO]/[WARN]` 前缀，详细信息写入 `ui.log`
- 菜单选项强制米黄色渲染（256 色优先，自动 fallback）
- 失败不退出菜单，日志路径统一走 `DATA_DIR`

## 关键实现

### 1) 选项 3 子菜单（扫描目录选择）
- 新增 `scan_menu()`：先列目录，再数字选择，再执行 scan。
- 目录来源优先级：
  1. `PTBD_SCAN_DIRS`（冒号分隔）
  2. 默认候选：
     - `/opt/PT-BDtool`
     - `/opt/PT-BDtool/bdtool-output`
     - `$HOME`
     - 当前目录 `$PWD`
     - 仓库目录 `$ROOT_DIR`
     - `BDTOOL_DATA_DIR`（若已解析）
- 仅展示存在且可读目录，去重。
- 支持 `0` 返回上一级。
- 选择后执行：`bdtool.sh scan <选定目录> --mode dry`。
- 失败仅一句提示并回主菜单，不退出 shell。

### 2) 默认中文 + 严格单语
- `lib/i18n.sh` 中 `LANG_CODE` 默认 `zh`。
- `set_lang` 策略：
  - 优先 CLI `--lang`
  - 其次显式环境变量 `LANG_CODE/BDTOOL_LANG`
  - 否则固定 `zh`
- 不再依据系统 `LANG/LC_ALL` 自动切语言。
- 全部菜单与交互文案通过 `t(KEY)` 输出，按当前语言单语显示。

### 3) 屏幕最小输出（隐藏 INFO 刷屏）
- `lib/ui.sh` 增加两套接口：
  - 屏幕层：`screen_text/screen_success/screen_warn/screen_error`（无 `[INFO]` 前缀）
  - 交互日志层：`ui_log_info/ui_log_warn/ui_log_error`（写 `UI_LOG`，带时间戳）
- 菜单动作统一使用 `run_action()`：
  - 详细命令输出重定向到 `UI_LOG`
  - 屏幕仅显示一行结果 + “按回车返回菜单”

### 4) 菜单米黄色与兼容 fallback
- 在 `lib/ui.sh` 里实现能力检测：
  - `tput colors >= 256`：`MENU_OPT_COLOR='\033[38;5;223m'`
  - 否则 fallback：`\033[33m`
- 菜单选项行统一用 `color_menu_option` 包裹，并在行尾 `RESET`。
- 未对全局文本做绿色覆盖，绿色仅用于成功提示。

### 5) 失败不退出菜单 + 数据目录路径修复
- 主循环 `while true` 仅在 Quit 退出。
- 子动作失败只影响当前动作提示，不影响菜单循环。
- 日志目录统一由 `resolve_data_dir()` 计算：
  - `/opt/PT-BDtool/bdtool-output`（可写或 root）
  - 否则 `$HOME/.local/share/pt-bdtool/bdtool-output`
  - 再兜底 `/tmp/pt-bdtool/bdtool-output`
- 不再出现 `/usr/local/bin/bdtool-output`。

## 改动文件清单
- `/media/15sir/DataHub/Github/PT-BDtool/lib/ui.sh`
- `/media/15sir/DataHub/Github/PT-BDtool/lib/i18n.sh`
- `/media/15sir/DataHub/Github/PT-BDtool/bdtool`
- `/media/15sir/DataHub/Github/PT-BDtool/FINAL_REPORT.md`

## 日志路径
- `RUN_LOG`: `/home/15sir/.local/share/pt-bdtool/bdtool-output/logs/run.log`
- `UI_LOG`: `/home/15sir/.local/share/pt-bdtool/bdtool-output/logs/ui.log`
- `REG_LOG`: `/home/15sir/.local/share/pt-bdtool/bdtool-output/logs/ux-regression.log`

## 复测结果

| 用例 | 命令 | 结果 | 说明 |
|---|---|---|---|
| 默认中文：日志后退出 | `printf "5\n\n7\n" \| bdtool` | PASS | 默认中文，屏幕无 `[INFO]` 前缀 |
| 默认中文：scan 子菜单返回 | `printf "3\n0\n7\n" \| bdtool` | PASS | 进入目录子菜单后返回主菜单 |
| 英文模式退出 | `printf "7\n" \| bdtool --lang en` | PASS | 全英文界面 |
| scan 失败回菜单 | `printf "3\n2\n\n7\n" \| bdtool` | PASS | 失败后仅一句提示并回菜单 |
| 颜色能力记录 | `tput colors` + ANSI 示例写入 `REG_LOG` | PASS | 记录 `tput_colors=256` 与 `38;5;223` 示例 |

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
