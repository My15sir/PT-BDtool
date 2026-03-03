# FINAL_REPORT

## 问题原因

用户报错：

```text
[ERROR] missing lib/ui.sh
```

根因：`install.sh` 在脚本开头直接 `source "$SCRIPT_DIR/lib/ui.sh"`。当用 `bash <(curl -fsSL .../install.sh)` 执行时，`SCRIPT_DIR` 指向临时 FD 路径，不是仓库目录，导致 `lib/ui.sh` 不存在，脚本立即退出。

## 修复方案

对 `install.sh` 增加“自举阶段”并保持无人值守：

1. 在 `source lib/ui.sh` 之前做检测：若缺失 `lib/ui.sh`，进入自举模式。
2. 自举流程：
   - `mktemp -d` 建临时目录。
   - 优先 `git clone --depth 1 --branch main` 拉取完整仓库。
   - clone 失败则回退为 `codeload` tarball 下载 + `tar -xzf` 解压。
   - 获取完整仓库后，以 `PTBD_BOOTSTRAP_DONE=1` 重新执行仓库内 `install.sh`。
3. 清理策略：默认清理临时目录；`KEEP_TMP=1` 可保留排障。
4. 无人值守：不做交互输入，默认值可由环境变量覆盖。
5. 超时与日志：
   - 自举命令统一 300s 超时。
   - 自举日志也写入 `./bdtool-output/logs/run.log`。
6. 保持原安装行为：仓库内运行时仍沿用原安装逻辑（依赖安装、下载 bdtool、可选 BDInfo 安装）。

## 改动文件清单

- `/media/15sir/DataHub/Github/PT-BDtool/install.sh`
- `/media/15sir/DataHub/Github/PT-BDtool/install.sh.bak`
- `/media/15sir/DataHub/Github/PT-BDtool/FINAL_REPORT.md`

## git 状态记录

修改前已记录工作区状态；当前状态：

```text
 M install.sh
 M install.sh.bak
```

## 复跑测试结果

日志文件：`/media/15sir/DataHub/Github/PT-BDtool/bdtool-output/logs/auto-fix-install.log`

### 测试1（仓库内）

命令：

```bash
cd /media/15sir/DataHub/Github/PT-BDtool && bash install.sh
```

结果：`rc=0`（成功）

关键日志片段：

```text
===== 2026-03-03 16:26:02 test1 start: bash install.sh =====
[INFO] Install started
[INFO] 下载 bdtool...
[SUCCESS] BDInfo is available
[INFO] Install completed
===== 2026-03-03 16:26:02 test1 end rc=0 =====
```

### 测试2（模拟 curl|bash）

说明：本地改动未发布到 GitHub remote，真实 `curl -fsSL https://raw.githubusercontent...` 拉到的是远端旧版本，无法直接验证本地修复。因此按要求使用“非仓库目录本地模拟 raw 执行”。

命令（模拟）：

```bash
tmpd=$(mktemp -d)
cp /media/15sir/DataHub/Github/PT-BDtool/install.sh "$tmpd/install.sh"
bash "$tmpd/install.sh"
```

结果：`rc=0`（成功）

关键日志片段：

```text
===== 2026-03-03 16:27:19 test2 start: simulated raw install.sh ... =====
[bootstrap] 检测到缺少 lib/ui.sh，进入自举模式。
[bootstrap] 尝试 git clone 仓库...
[bootstrap] 自举完成，切换到仓库目录继续安装：/tmp/ptbd-install-.../PT-BDtool
[INFO] Install started
[INFO] 下载 bdtool...
[INFO] Install completed
===== 2026-03-03 16:27:21 test2 end rc=0 =====
```

## 回滚命令

```bash
cd /media/15sir/DataHub/Github/PT-BDtool
cp -f install.sh.bak install.sh
cp -f FINAL_REPORT.md.bak FINAL_REPORT.md 2>/dev/null || true
```

可选 git 回滚方案：

```bash
cd /media/15sir/DataHub/Github/PT-BDtool
git checkout -- install.sh install.sh.bak FINAL_REPORT.md
```
