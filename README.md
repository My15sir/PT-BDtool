# PT-BDtool

本项目为 AI 生成项目。
不接受反馈。
有问题请自行排查。

## 复制以下命令安装
```bash
set -euo pipefail
cd ~
if [ -d PT-BDtool/.git ]; then
  cd PT-BDtool && git pull --ff-only
else
  git clone https://github.com/My15sir/PT-BDtool.git
  cd PT-BDtool
fi
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
pt --help
```

## 复制以下命令启动
```bash
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
pt
```

说明：`pt` 会自动识别音频/视频/原盘输入并进入对应流程。
交互说明：
- 扫描菜单输入 `/` 可快捷触发默认全盘扫描（自动排除 `/proc /sys /dev /run`）。
- 扫描和打包下载阶段会显示百分比进度，并到 `100%`。
- 下载目录留空时默认落到实际用户桌面（`~/Desktop/PT-BDtool`）。

## 复制以下命令卸载
```bash
set -euo pipefail
rm -f "$HOME/.local/bin/bdtool" "$HOME/.local/bin/ptbd-start" "$HOME/.local/bin/pt" "$HOME/.local/bin/pts"
rm -rf "$HOME/.local/share/pt-bdtool/PT-BDtool-app"
rm -f /usr/local/bin/bdtool /usr/local/bin/ptbd-start /usr/local/bin/pt /usr/local/bin/pts 2>/dev/null || true
```
