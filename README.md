# PT-BDtool

PT-BDtool 是一个面向 PT 发布素材整理的 Bash 工具，提供安装、体检、扫描/生成、清理和日志查看功能。

## 一行安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/My15sir/PT-BDtool/main/install.sh)
```

说明：安装入口会优先进入交互菜单（默认中文），而不是直接执行安装动作。

## 安装后主菜单（1-7）

1. 一键安装
2. 环境体检
3. 扫描/生成
4. 清理
5. 查看日志
6. 切换语言
7. 退出

菜单为循环菜单：任一动作执行后都会回到主菜单，只有选择 `7` 才退出。

## 扫描二级菜单

进入 `3) 扫描/生成` 后：

1. 扫描全盘
2. 扫描指定目录
3. 后台扫描（可选保留）
0. 返回

### 全盘扫描安全提示

选择全盘扫描会先显示风险说明：
- 高 IO
- 长时间运行
- 可能影响系统性能

必须输入 `1` 才继续。

### 指定目录扫描

- 输入扫描路径
- 自动做路径校验
- 校验失败会提示并继续重试

## 清理机制（安全）

- 清理仅基于 manifest 白名单：`$DATA_DIR/state/manifest.txt`
- 默认 `dry-run`（不实际删除）
- 实际删除前二次确认
- 只允许删除 `$DATA_DIR` 内的脚本产物，禁止删除用户原有文件

## 数据目录（DATA_DIR）规则

优先：
- `/opt/PT-BDtool/bdtool-output`

否则：
- `$HOME/.local/share/pt-bdtool/bdtool-output`

兜底：
- `/tmp/pt-bdtool/bdtool-output`

不会使用 `/usr/local/bin` 作为数据目录。

## 日志位置

- 运行日志：`$DATA_DIR/logs/run.log`
- 交互详情日志：`$DATA_DIR/logs/ui.log`
- 复测日志：`$DATA_DIR/logs/ux-regression.log`

## 常见问题

### 为什么 curl|bash 后不是直接安装，而是先进入菜单？

这是当前设计：先给出完整 1-7 菜单，用户可以选择“安装/体检/扫描”等动作，避免脚本直接执行重操作。

### 为什么有时看不到彩色菜单？

菜单选项优先使用 256 色米黄色（`38;5;223`），终端不支持时自动回退黄色（`33`）。
