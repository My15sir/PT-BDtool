# FINAL_REPORT

## 根因
依赖安装阶段使用 `apt-get` 直接执行，缺少统一超时/重试与锁等待上限控制。遇到 apt 锁占用或网络问题时会长时间等待，用户感知为“卡死”。

## 修复点
1. 在 `install.sh` 增加统一依赖安装函数：
- `is_cmd_installed(cmd)`
- `wait_for_apt_lock(max_wait)`
- `run_timeout_retry(desc, cmd...)`
- `apt_update()`
- `apt_install(pkgs...)`

2. apt/dpkg 稳定性约束（默认）：
- 非交互：`DEBIAN_FRONTEND=noninteractive`
- 自动确认：`-y`
- 低噪音：`-qq`（`APT_QUIET=0` 可关闭）
- 单步超时：`APT_TIMEOUT=300`
- 重试：`APT_RETRY_MAX=3`（退避 1/2/4 秒）
- 锁等待上限：`APT_LOCK_WAIT=60`

3. 锁占用处理：
- 检测 apt/dpkg/unattended-upgrades 进程与常见锁文件
- 超过上限直接失败，不再无限等待
- 若可用，尝试通过 `fuser/lsof` 输出占用进程信息

4. 阶段化提示：
- 先检查命令是否已安装
- 缺失时显示 `apt-get update` / `apt-get install` 正在执行与超时秒数
- 失败时给出明确可操作建议（检查网络/源、手动 `apt-get update`、检查 unattended-upgrades）

5. README 同步：
- 增加“依赖安装稳定性”与排障命令说明

## 改动文件
- `install.sh`
- `README.md`
- `FINAL_REPORT.md`

## 复测（真实执行）
1. 触发缺依赖安装流程（额外依赖注入）：
```bash
timeout 300 env PTBD_EXTRA_DEPS='ptbd_missing_zip_cmd:zip' APT_TIMEOUT=120 APT_RETRY_MAX=2 APT_LOCK_WAIT=20 bash install.sh --non-interactive
```
结果：PASS（进入缺依赖安装分支，检测到锁占用并在上限后退出，未无限等待）。

2. 触发失败建议输出：
```bash
timeout 300 env PTBD_EXTRA_DEPS='ptbd_missing_bad_cmd:ptbd-package-not-exists-xyz' APT_TIMEOUT=60 APT_RETRY_MAX=1 APT_LOCK_WAIT=20 bash install.sh --non-interactive
```
结果：PASS（输出“有其他 apt 进程占用”与三条可操作建议，流程可控退出）。

## 回滚命令
```bash
cd /media/15sir/DataHub/Github/PT-BDtool
mv install.sh.bak install.sh
```
