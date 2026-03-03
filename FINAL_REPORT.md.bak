# FINAL_REPORT

## 问题原因

现象：安装与参数校验阶段缺少统一错误态体验，输入校验失败时提示不统一，且无人值守场景容易出现流程中断风险。

目标对齐：参考 `Auto-Seedbox-PT/auto_seedbox_pt.sh` 的交互风格，统一实现 `[ERROR]/[WARN]/[INFO]/[HINT]` 分级输出、可恢复错误重试、不可恢复错误统一退出并指向日志。

## 修复方案

1. 重构 `lib/ui.sh` 为统一 UI 层。
2. 增加错误态组件与提示组件：`error/warn/info/success/hint/error_box`。
3. 增加可重试输入函数：
   - `prompt_secret_with_rules(var_name, prompt, min_len, max_retry, allow_empty)`
   - `prompt_with_default_and_validate(var_name, prompt, default, validator_fn, max_retry)`
4. 保持兼容：保留 `log_info/log_warn/log_err/log_success` 别名，旧调用不失效。
5. 统一日志：`setup_log_redirection` + `run_cmd_logged` + `execute_with_spinner`，所有 stdout/stderr 追加到 `./bdtool-output/logs/run.log`。
6. 不可恢复错误统一 `die`：打印错误并提示日志路径。
7. `install.sh` 接入：
   - 新增 `ERR trap` 未捕捉异常提示。
   - 新增密码输入校验流程，支持无人值守默认值与参数覆盖。
   - 新增 `DEMO=1` 演示模式：自动模拟一次短密码失败后重试成功。

## 错误态覆盖点

- 密码长度不足（可恢复/可重试）：
  - 错误文案：`[ERROR] 安全性不足：密码长度必须 ≥ 12 位！`
  - 修复提示：`[HINT] 请重新输入，建议使用 16 位以上。`
  - 自动重试：最多 `max_retry` 次。
- 参数直传密码不合法（不可恢复）：
  - `--password short` 直接报错并 `die` 退出。
  - 明确提示日志路径：`./bdtool-output/logs/run.log`。
- 未捕捉异常（不可恢复）：
  - `trap ERR` 统一输出错误与日志路径（可控 tail 日志）。

## 可重试输入函数说明

### prompt_secret_with_rules

- 隐藏输入（TTY 下 `read -s`）。
- 支持无人值守：`BDTOOL_NO_PROMPT=1` 自动选择默认值或环境变量。
- 支持重试队列（用于 DEMO 自动化）：`PROMPT_INPUTS_<VAR>`。
- 长度不足时输出 `ERROR + HINT` 并重试。
- 超过重试上限执行 `die("多次输入失败，已退出。")`。

### prompt_with_default_and_validate

- 支持默认值。
- 支持验证函数注入（返回 0 为通过）。
- 校验失败输出 `ERROR + HINT` 并重试。
- 超过重试上限统一 `die`。

## 改动/新增文件清单

- `/media/15sir/DataHub/Github/PT-BDtool/lib/ui.sh`
- `/media/15sir/DataHub/Github/PT-BDtool/install.sh`
- `/media/15sir/DataHub/Github/PT-BDtool/FINAL_REPORT.md`

备份文件：
- `/media/15sir/DataHub/Github/PT-BDtool/lib/ui.sh.bak`
- `/media/15sir/DataHub/Github/PT-BDtool/install.sh.bak`
- `/media/15sir/DataHub/Github/PT-BDtool/FINAL_REPORT.md.bak`

## 复跑测试结果

测试日志：
- 运行日志：`/media/15sir/DataHub/Github/PT-BDtool/bdtool-output/logs/run.log`
- 演示日志：`/media/15sir/DataHub/Github/PT-BDtool/bdtool-output/logs/ui-error-demo.log`

| 用例 | 命令 | 结果 |
|---|---|---|
| RETEST1 | `timeout 300 bash install.sh --dry-run` | PASS (RC=0) |
| RETEST2 | `timeout 300 DEMO=1 BDTOOL_NO_PROMPT=1 bash install.sh --dry-run` | PASS (RC=0) |
| RETEST3 | `timeout 300 BDTOOL_NO_PROMPT=1 bash install.sh --dry-run --password short` | PASS（按预期失败，RC=1，输出 ERROR+HINT+日志路径） |

关键演示片段（来自 `ui-error-demo.log`）：

```text
[INFO] DEMO=1：将自动演示一次短密码失败并重试成功。
[ERROR] 安全性不足：密码长度必须 ≥ 12 位！
[HINT] 请重新输入，建议使用 16 位以上。
[SUCCESS] DEMO：密码重试流程验证通过。
```

## 回滚命令

```bash
cd /media/15sir/DataHub/Github/PT-BDtool
cp -f lib/ui.sh.bak lib/ui.sh
cp -f install.sh.bak install.sh
cp -f FINAL_REPORT.md.bak FINAL_REPORT.md
```

可选 git 回滚：

```bash
cd /media/15sir/DataHub/Github/PT-BDtool
git checkout -- lib/ui.sh install.sh FINAL_REPORT.md
```
