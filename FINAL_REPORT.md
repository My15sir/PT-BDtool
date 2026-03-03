# FINAL_REPORT

## 问题根因

安装入口 `install.sh` 在“stdin 非 TTY”场景（典型为 `bash <(curl ...)`）走了：
- `bdtool install --non-interactive`

这会直接执行“1) 一键安装”动作，而不是进入完整 1-7 主菜单，所以用户只看到：
- `1) 一键安装`
- `1) 一键安装 已完成`

## 修复内容

### 1) install.sh 入口修复
- 改为：无参数时统一进入主菜单入口 `bdtool --lang zh`。
- 菜单可交互/非交互判定下沉到 `bdtool` 内部处理。
- 保留 curl|bash 自举逻辑：拉完整仓库后进入同一入口。

### 2) 菜单输入通道修复（bdtool）
- 新增 `menu_can_interact()` 和 `menu_read_line()`。
- 支持三种输入来源：
  1. 直接 TTY stdin
  2. 管道 stdin（`printf ... | bash install.sh`）
  3. `/dev/tty` 回退（解决 curl|bash 下 stdin 不是 tty 的情况）
- 主菜单与扫描二级菜单统一使用该读取逻辑。

### 3) 主菜单循环稳定性
- 主菜单保持 1-7 完整显示。
- 每次动作后返回主菜单。
- 仅 `7` 退出。
- 菜单失败不退出到 shell。

### 4) 选项 3（二级扫描菜单）
- 保留并验证以下项：
  1. 扫描全盘（含风险提示）
  2. 扫描指定目录（路径输入、校验失败重试）
  0. 返回

### 5) 选项 4（清理）安全性
- 默认 dry-run。
- 仅基于 manifest 白名单删除。
- 路径必须在 `$DATA_DIR` 内。
- 不删除用户原有文件。

### 6) README 同步
已更新 `README.md`，新增并同步：
- 一行安装命令
- 安装后主菜单 1-7 说明
- 扫描二级菜单说明
- 清理安全策略（manifest）
- DATA_DIR 规则
- 日志位置（run.log/ui.log/ux-regression.log）
- FAQ：为何 curl|bash 先进入菜单

## 改动文件
- `/media/15sir/DataHub/Github/PT-BDtool/install.sh`
- `/media/15sir/DataHub/Github/PT-BDtool/bdtool`
- `/media/15sir/DataHub/Github/PT-BDtool/README.md`
- `/media/15sir/DataHub/Github/PT-BDtool/FINAL_REPORT.md`

## 复测结果（真实执行）

日志文件：
- `/home/15sir/.local/share/pt-bdtool/bdtool-output/logs/ux-regression.log`

| 用例 | 命令 | 结果 |
|---|---|---|
| 主菜单完整性（含“2) 环境体检”） | `printf "7\n" \| bash install.sh 2>&1 \| grep -q '2) 环境体检'` | PASS |
| 直接退出 | `printf "7\n" \| bash install.sh` | PASS |
| 扫描菜单进入并返回 | `printf "3\n0\n7\n" \| bash install.sh` | PASS |
| 清理安全流程（dry-run + 返回） | `printf "4\n2\n0\n7\n" \| bash install.sh` | PASS |

## 回滚命令

```bash
cd /media/15sir/DataHub/Github/PT-BDtool
cp -f install.sh.bak install.sh
cp -f bdtool.bak bdtool
cp -f README.md.bak README.md
cp -f FINAL_REPORT.md.bak FINAL_REPORT.md
```

可选 git 回滚：

```bash
cd /media/15sir/DataHub/Github/PT-BDtool
git checkout -- install.sh bdtool README.md FINAL_REPORT.md
```
