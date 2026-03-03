# FINAL_REPORT

## 本次重构目标
已将 PT-BDtool 重构为“极简、稳定、好用”版本：
- 安装后默认进入三项主菜单（默认中文，严格单语）
- 核心闭环：扫描 -> 选择条目 -> 生成产物 -> 下载打包 -> 临时清理
- 默认不产生日志，仅在出错时写最小错误文件

## 变更点
1. `install.sh`
- 支持仓库内运行与 curl|bash 自举运行。
- 先执行依赖检测：
  - 已安装：输出“<命令> 已安装”
  - 缺失：自动安装（apt-get），需 root 时自动使用 root/sudo
  - 安装失败：给出一句话错误并写 `last_error.txt`
- 自动安装 `bdtool` 命令入口（优先 `/usr/local/bin`，否则 `~/.local/bin`）。
- 依赖处理完成后自动进入极简菜单。

2. `bdtool`
- 主菜单固定三项：
  1) 扫描
  2) 切换语言
  3) 退出
- 扫描二级菜单：
  1) 扫描全盘（风险提示 + 输入 1 继续）
  2) 扫描指定目录（目录校验 + 重试）
  0) 返回
- 扫描规则：排除 `/proc /sys /dev /run /tmp`，识别 VIDEO/BDMV/ISO。
- 扫描后展示结果列表（前 50 条），支持编号选择；非法输入最多 3 次。
- 生成产物：
  - VIDEO -> `信息/mediainfo.txt`
  - BDMV/ISO -> `信息/bdinfo.txt`
  - 截图固定 `1.png..6.png`（不足自动补齐，占位图策略已启用）
- 生成完成后提供下载：
  - 打包到 `~/Downloads/PT-BDtool/`（优先 zip，否则 tar.gz）
- 下载后支持清理：
  - 仅清理本次任务临时目录（`$OUTPUT_ROOT/cache/...`）
  - 不删除源文件。

3. `lib/ui.sh`
- UI 简化：无 `[INFO]` 前缀刷屏。
- 菜单颜色：优先 256 色米黄色 `38;5;223`，fallback `33`。
- 统一数据目录计算与 `OUTPUT_ROOT`。
- 提供最小错误文件写入能力：`$OUTPUT_ROOT/last_error.txt`。

4. `lib/i18n.sh`
- 默认中文（`LANG_CODE=zh`）。
- 仅显式 `--lang en` 或 `LANG_CODE=en` 切换英文。
- 菜单/提示严格单语渲染。

5. `README.md`
- 已同步新流程、新菜单、新扫描闭环、下载与清理安全策略、错误文件策略。

## 复测结果（真实执行）
| 测试项 | 命令 | 结果 |
|---|---|---|
| 安装后进入菜单 | `script -q -c "bash install.sh --lang zh" ...` | PASS（依赖检测后出现 1/2/3 菜单） |
| 指定目录扫描（空目录） | `bdtool --lang zh` 交互输入 `1->2->/tmp/ptbd-empty` | PASS（显示“未发现可处理条目”） |
| 指定目录扫描并生成 | `bdtool --lang zh` 交互输入 `1->2->/tmp/ptbd-src2->1` | PASS（生成 `信息/*.txt` + `1..6.png`） |
| 下载打包 | 同上选择下载 | PASS（产物写入 `~/Downloads/PT-BDtool/*.zip`） |
| 清理临时文件 | 下载后选择清理 | PASS（仅清理 `$OUTPUT_ROOT/cache/<task>`，未删除源文件） |
| 英文切换 | `bdtool --lang en` 交互输入 `3` | PASS |

## 占位策略说明
当系统缺少真实截图/分析工具或处理失败时：
- 文本信息文件使用占位内容
- PNG 使用内置 1x1 占位图并补齐至 6 张

## 改动文件
- `install.sh`
- `bdtool`
- `lib/ui.sh`
- `lib/i18n.sh`
- `README.md`
- `FINAL_REPORT.md`

## 回滚命令
```bash
cd /media/15sir/DataHub/Github/PT-BDtool
cp -f install.sh.bak install.sh
cp -f bdtool.bak bdtool
cp -f lib/ui.sh.bak lib/ui.sh
cp -f lib/i18n.sh.bak lib/i18n.sh
cp -f README.md.bak README.md
cp -f FINAL_REPORT.md.bak FINAL_REPORT.md
chmod +x install.sh bdtool
```
