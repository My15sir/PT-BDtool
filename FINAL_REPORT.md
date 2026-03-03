# FINAL_REPORT

## 根因分析
触发点在 `install.sh` 的 bootstrap 分支：
- 旧实现仅尝试 `git clone` + 单一 tarball 路径，失败后直接报“自举失败：无法获取完整仓库”。
- 缺少统一重试/超时与错误分类，导致用户无法判断是 DNS、证书、HTTP 还是网络超时问题。

## 修复点
1. `install.sh` bootstrap 重构为三策略自动降级：
- 策略1：`git clone --depth=1`
- 策略2：tarball 下载并解压
- 策略3：zipball 下载并解压

2. 全策略统一执行保障：
- 每次执行 300 秒超时
- 最多 3 次重试
- 指数退避 1s/2s/4s

3. 新增网络探测：
- `detect_network()` 快速探测 `github.com` 与 `raw.githubusercontent.com`

4. 新增错误分类与可行动提示：
- DNS：提示检查 `/etc/resolv.conf`
- TLS/证书：提示安装 `ca-certificates`
- HTTP 403/404：提示检查 URL/分支名
- 超时：提示网络不通/代理受限
- 命令缺失：提示安装 `git/curl/wget/tar/unzip`

5. 自举调试输出：
- 失败时保留临时目录并输出 `bootstrap-debug.log` 路径
- 记录 stderr、退出码、HTTP 状态码

6. 成功后入口修正：
- 自举成功后切换到真实仓库根目录并执行 `bash <repo>/install.sh`，确保后续走正确入口。

7. `README.md` 同步更新：
- 新增自举策略说明
- 新增失败排查命令
- 新增离线安装方案

## 改动文件
- `install.sh`
- `README.md`
- `FINAL_REPORT.md`

## 复测结果
| 测试项 | 命令 | 结果 |
|---|---|---|
| 强制跳过 git，验证 tarball 降级 | `PTBD_BOOTSTRAP_FORCE_NO_GIT=1 bash /tmp/ptbd-bootstrap-test.sh --non-interactive` | PASS（策略2 tarball 成功） |
| 模拟下载失败并验证提示 | `PTBD_BOOTSTRAP_FORCE_NO_GIT=1 PTBD_BOOTSTRAP_TARBALL_URL=...not-exists... PTBD_BOOTSTRAP_ZIPBALL_URL=...not-exists... KEEP_TMP=1 bash /tmp/ptbd-bootstrap-test-bad.sh --non-interactive` | PASS（输出 HTTP 404 分类提示 + 调试日志 + 离线方案） |

## 回滚命令
```bash
cd /media/15sir/DataHub/Github/PT-BDtool
mv install.sh.bak install.sh
```
