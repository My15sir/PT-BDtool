# FINAL_REPORT

## 变更目标

实现“安装完成后自动跳转数字菜单界面”，并保证：
- 仅在交互终端（TTY）自动进入菜单。
- `--non-interactive` 或非 TTY 绝不进入菜单。
- 菜单与帮助支持中英双语。

## 根因分析

用户“安装后看不到菜单/选项”来自两个问题：
1. 安装器此前只提示 `Next: bdtool doctor`，未做安装成功后的菜单自动跳转。
2. 入口脚本默认 `BDTOOL_NO_PROMPT=1`，会把无参数执行判定为非交互路径，导致只输出 help。

## 修复点

1. `install.sh`：安装成功后自动拉起菜单
- 新增 `auto_launch_menu_after_install`。
- 条件：
  - `AUTO_LAUNCH_MENU=1`（默认开启）
  - 非 `--non-interactive`
  - stdin 为 TTY
- 启动逻辑：
  - 优先 `command -v bdtool`
  - 兜底 `./bdtool` 或 `./ptbd`
  - 使用当前语言 `--lang <zh|en>`
- 新增 `--non-interactive` 参数，明确禁止自动菜单。

2. `bdtool`：数字菜单与策略
- 无参数：
  - TTY 且非 `--non-interactive` → 进入 `menu_loop`
  - 非 TTY → 输出 help 并退出（退出码 0）
- 菜单项（1-7）全部数字触发：
  1) install
  2) doctor
  3) scan（无能力时 SKIP）
  4) clean（危险操作，二次确认）
  5) logs（默认 tail run.log）
  6) switch language
  7) quit
- 输入规则：只接受 `1-7` 或 `q/Q`；非法输入输出红色 ERROR + HINT 并重试。
- 保留子命令模式：`install/doctor/scan/clean/logs/--help`。

3. 双语策略
- `--lang zh|en` 强制语言。
- 默认语言：`LC_ALL/LANG` 含 `zh` 用中文，否则英文；未设置默认中文。

## 改动文件清单

- `/media/15sir/DataHub/Github/PT-BDtool/install.sh`
- `/media/15sir/DataHub/Github/PT-BDtool/bdtool`
- `/media/15sir/DataHub/Github/PT-BDtool/FINAL_REPORT.md`

## 备份文件

- `/media/15sir/DataHub/Github/PT-BDtool/install.sh.bak`
- `/media/15sir/DataHub/Github/PT-BDtool/bdtool.bak`
- `/media/15sir/DataHub/Github/PT-BDtool/FINAL_REPORT.md.bak`

## 复测结果（真实执行）

日志文件：
- 统一日志：`./bdtool-output/logs/run.log`
- 菜单拉起测试：`./bdtool-output/logs/menu-launch-test.log`

| 用例 | 命令 | 结果 |
|---|---|---|
| INSTALL_AUTO_MENU | `printf "7\n" \| script -qec 'bash ./install.sh' /dev/null` | PASS（安装后自动进入菜单并退出） |
| MENU_DISPATCH_LOGS_QUIT | `printf "5\n7\n" \| script -qec 'bdtool --lang zh' /dev/null` | PASS（数字 5 执行 logs，随后 7 退出） |
| NONTTY_POLICY | `printf "7\n" \| bdtool` | PASS（按策略输出 help 并退出） |
| COMMAND_PATH | `command -v bdtool` | PASS |
| HELP | `bdtool --help --lang zh` | PASS |
| DOCTOR | `bdtool doctor` | PASS |
| LOGS | `bdtool logs --tail 20` | PASS |

## 回滚命令

```bash
cd /media/15sir/DataHub/Github/PT-BDtool
cp -f install.sh.bak install.sh
cp -f bdtool.bak bdtool
cp -f FINAL_REPORT.md.bak FINAL_REPORT.md
```

可选 git 回滚：

```bash
cd /media/15sir/DataHub/Github/PT-BDtool
git checkout -- install.sh bdtool FINAL_REPORT.md
```
