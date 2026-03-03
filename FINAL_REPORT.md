# FINAL_REPORT

## 本次目标
完成 PT-BDtool 的完整稳定化与极简化改造：
- 安装依赖不可无限等待（超时/重试/锁恢复）
- 主菜单极简三项
- 扫描支持多选批处理
- 产物目录统一为 `<OUTPUT_ROOT>/信息/<源文件目录名>/`
- 默认仅错误时写 `last_error.txt`

## 核心改动

### 1) install.sh 依赖安装稳定化
新增/重构：
- `is_cmd_installed()`
- `wait_for_apt_lock()`
- `run_timeout_retry()`
- `apt_update()`
- `apt_install()`
- 锁占用强制恢复（识别进程 -> TERM/KILL -> `dpkg --configure -a`）

行为满足：
- `DEBIAN_FRONTEND=noninteractive`
- `apt-get -y`
- 超时：`APT_TIMEOUT=300`（可配）
- 重试：`APT_RETRY_MAX=3`（1/2/4秒）
- 安装中每10秒输出 `仍在安装 ...`
- `apt-get update` 失败后仍尝试 `install` 一次
- 失败写 `last_error.txt` 并给一句话提示

### 2) bdtool 极简重构
- 主菜单仅：
  1) 扫描
  2) 切换语言
  3) 退出
- 扫描二级菜单：
  1) 扫描全盘（风险+二次确认）
  2) 扫描指定目录（最多3次重试）
  0) 返回
- 扫描结果：最多显示5条，超出提示省略
- 支持多选输入：`1`、`1 2 3`、`0`
- 多选批量处理完成后返回扫描菜单

### 3) 产物目录统一
输出路径统一为：
- `<OUTPUT_ROOT>/信息/<源文件目录名>/`

规则实现：
- 视频：`mediainfo.txt + 1..6.png`
- 原盘/ISO：`bdinfo.txt`
- 名称安全化、长度限制、冲突 `_2/_3`
- 截图不足6张自动补齐

### 4) 下载与清理闭环
- 生成后可选下载 zip 到 `~/Downloads/PT-BDtool/`
- 下载后可选清理，仅删本次临时缓存，不删源文件

### 5) README 同步
README 已更新为当前流程与结构。

## 复测结果（真实执行）

1. install 启动 -> 依赖检测 -> 主菜单
- 命令：
  `script -q -c "bash install.sh --lang zh" ...`
- 结果：PASS（显示依赖检查后进入 1/2/3 主菜单）

2. 扫描指定目录 -> 显示 <=5 条
- 命令：`bdtool --lang zh` 交互输入扫描 `/tmp/ptbd-caseA`
- 结果：PASS（仅显示前5条，并提示“其余已省略”）

3. 多选 `1 2` -> 顺序生成、下载、清理、回到扫描菜单
- 命令：交互输入 `1 2`，每项选择下载+清理
- 结果：PASS（两个条目顺序处理，完成后回到扫描菜单）

4. 全盘扫描二次确认分支可触发
- 命令：进入全盘扫描并执行确认输入
- 结果：PASS（风险提示与确认分支触发）

5. 目录结构验证
- 结果：PASS，已生成：
  `<OUTPUT_ROOT>/信息/dir6_2/...`
  `<OUTPUT_ROOT>/信息/dir5_2/...`
  并包含 `mediainfo.txt` 与 `1..6.png`

## 改动文件
- `install.sh`
- `bdtool`
- `README.md`
- `FINAL_REPORT.md`

## 回滚命令
```bash
cd /media/15sir/DataHub/Github/PT-BDtool
mv install.sh.bak install.sh
cp -f bdtool.bak bdtool
cp -f README.md.bak README.md
cp -f FINAL_REPORT.md.bak FINAL_REPORT.md
chmod +x install.sh bdtool
```
