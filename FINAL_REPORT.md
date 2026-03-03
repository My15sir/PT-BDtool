# FINAL_REPORT

## 1) 能力清单（核心功能定义）

| 能力名称 | 旧触发方式 | 关键输入 | 关键输出 | 必须保持 | 允许变更 |
|---|---|---|---|---|---|
| 安装能力 | `./bdtool.sh install` / `bash install.sh` | `-k`, `--lang` | 安装 `bdtool` 可执行，尝试安装 `BDInfo` | 是 | 入口可变化、流程可重构 |
| 依赖体检 | `./bdtool.sh doctor` | 无 | 依赖检查结果（bash/find/sort/ffmpeg/ffprobe/mediainfo/BDInfo） | 是 | 展示样式可变化 |
| 状态检查 | `./bdtool.sh status` | 无 | 安装路径、版本、依赖 PASS/FAIL | 是 | 文案/样式可变化 |
| 扫描处理 | `./bdtool.sh <path>` / `./bdtool.sh scan <path> --out <dir>` | 路径、`--mode dry`、`--out`、`--jobs` 等 | `bdtool-output/.../信息/` 内 `mediainfo.txt`/`1.png~6.png`/`bdinfo.txt`(BDMV/ISO) | 是 | 新入口与默认流程可变 |
| 清理输出 | `./bdtool.sh clean` | 无 | 删除 `./bdtool-output` | 是 | 可增加更清晰提示 |
| 日志记录 | 历史上不统一 | 命令执行输出 | `./bdtool-output/logs/run.log` | 是（本次新增强制） | 输出格式可优化 |

## 2) 对标交互组件抽取（Auto-Seedbox-PT）

抽取来源：`Auto-Seedbox-PT/auto_seedbox_pt.sh`

- 彩色等级日志：`log_info/log_warn/log_err`
- 统一 spinner 执行器：`execute_with_spinner`
- 分阶段输出：`====` 分隔 + 阶段标题
- 输入交互：默认值输入、非法输入重复提示
- 失败统一提示日志位置：失败文案明确指向日志

## 3) 改动/新增文件列表

- 修改：`PT-BDtool/lib/ui.sh`
- 修改：`PT-BDtool/install.sh`
- 新增：`PT-BDtool/ptbd`
- 新增：`PT-BDtool/full-test.sh`
- 新增：`PT-BDtool/FINAL_REPORT.md`
- 备份：`PT-BDtool/lib/ui.sh.bak`
- 备份：`PT-BDtool/install.sh.bak`
- 已有备份沿用：`PT-BDtool/bdtool.sh.bak`

## 4) 新入口说明（智能、简洁、一键）

```bash
./ptbd --help
./ptbd install
./ptbd doctor
./ptbd scan
./ptbd clean
```

- `ptbd install`：默认 dry-run 智能检查（无人值守安全）
- `ptbd install --apply`：执行真实安装
- `ptbd install --apply --with-deps`：真实安装并尝试安装依赖
- `ptbd scan`：默认自动生成 smoke 输入并 dry 扫描（无人值守不阻塞）
- 全部命令统一日志到：`./bdtool-output/logs/run.log`

## 5) 旧用法 → 新用法迁移表

| 旧用法 | 新用法 | 说明 |
|---|---|---|
| `./bdtool.sh install` | `./ptbd install` | 默认 dry-run；若需真实安装用 `--apply` |
| `./bdtool.sh doctor` | `./ptbd doctor` | 能力等价 |
| `./bdtool.sh /path/to/videos` | `./ptbd scan /path/to/videos --full` | 新入口默认 dry，`--full` 开启完整处理 |
| `./bdtool.sh scan /path --out outdir` | `./ptbd scan /path --full --out outdir` | 参数透传到 `bdtool.sh` |
| `./bdtool.sh clean` | `./ptbd clean` | 能力等价 |
| `bash install.sh` | `./ptbd install --apply` | 推荐走统一入口 |

## 6) 输出/路径/格式变化

- 新增统一日志：`./bdtool-output/logs/run.log`
- 新增全流程测试日志：`./bdtool-output/logs/full-test.log`
- 新增测试结果清单：`./bdtool-output/logs/full-test-results.tsv`
- 新入口默认行为变化：`ptbd scan` 默认 `--mode dry`（可 `--full` 切换）
- 原 `bdtool.sh` 仍可继续使用（能力集合保留）

## 7) 能力触发方式与验证方式

| 能力 | 新触发方式 | 验证方式 |
|---|---|---|
| install | `./ptbd install` / `./ptbd install --apply` | 查看命令返回码 + `run.log` |
| doctor | `./ptbd doctor` | 输出依赖检查结果；返回码 0 |
| scan | `./ptbd scan` / `./ptbd scan /path --full` | 生成 `bdtool-output/.../信息/` 结构 |
| clean | `./ptbd clean` | `bdtool-output` 被清理 |
| 错误处理 | 传错命令：`./ptbd bad` | 返回非 0，提示查看 `run.log` |

## 8) 无人值守全流程测试结果

测试脚本：`./full-test.sh`

| 步骤 | 状态 | 返回码 | 日志 |
|---|---:|---:|---|
| help | PASS | 0 | `bdtool-output/logs/full-test.log` |
| doctor | PASS | 0 | `bdtool-output/logs/full-test.log` |
| install-dry | PASS | 0 | `bdtool-output/logs/full-test.log` |
| scan | PASS | 0 | `bdtool-output/logs/full-test.log` |
| clean | PASS | 0 | `bdtool-output/logs/full-test.log` |
| bad-args | FAIL(预期) | 1 | `bdtool-output/logs/full-test.log` |

说明：
- 每条步骤均有 300 秒超时保护；超时会记为 `TIMEOUT` 并继续后续步骤。
- 测试失败不中断，持续执行直到最后一步。

## 9) 已知问题与下一步建议

- `ptbd scan` 默认 dry 模式，若需要真实截图/MediaInfo，请显式加 `--full`。
- `install --apply` 涉及联网和权限环境差异，建议在目标机器上再做一次真实安装验证。

## 10) 回滚命令（逐文件 .bak 恢复）

```bash
cd /media/15sir/DataHub/Github/PT-BDtool
cp -f lib/ui.sh.bak lib/ui.sh
cp -f install.sh.bak install.sh
cp -f bdtool.sh.bak bdtool.sh
rm -f ptbd full-test.sh FINAL_REPORT.md
```
