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
- 主菜单选择“扫描”后会直接执行默认全盘扫描（自动排除 `/proc /sys /dev /run`）。
- 扫描菜单输入 `/` 仍可作为快捷触发。
- 扫描和打包下载阶段会显示百分比进度，并到 `100%`。
- 下载目录留空时默认落到实际用户桌面（`~/Desktop/PT-BDtool`）。
- 条目处理完成后会自动下载，再自动清理本次生成目录。

## VPS 自动回传到本地
项目现已支持正式的“回传模式”，通过 `BDTOOL_RETURN_MODE` 控制：

- `local`：默认模式；本地保存到下载目录。SSH/VPS 会话下默认保存到 `~/PT-BDtool-downloads`
- `http`：处理完成后，自动 `PUT` 上传到你提供的 HTTP 接收端
- `scp`：处理完成后，自动通过 `scp` 回传到你指定的目标机器目录

### 方案一：HTTP 回传
推荐用于 VPS 通过反向隧道回传到你的本机：

```bash
export BDTOOL_RETURN_MODE=http
export BDTOOL_RETURN_HTTP_URL='http://127.0.0.1:18080/upload'
pt
```

兼容旧变量：`BDTOOL_CLIENT_UPLOAD_URL` 仍然可用。

### 方案二：SCP 回传
推荐优先使用 SSH 密钥认证：

```bash
export BDTOOL_RETURN_MODE=scp
export BDTOOL_RETURN_SCP_HOST='127.0.0.1'
export BDTOOL_RETURN_SCP_PORT='10022'
export BDTOOL_RETURN_SCP_USER='your-local-user'
export BDTOOL_RETURN_SCP_REMOTE_DIR='/home/your-local-user/Downloads/PT-BDtool'
export BDTOOL_RETURN_SCP_IDENTITY_FILE="$HOME/.ssh/id_ed25519"
pt
```

可选变量：
- `BDTOOL_RETURN_SCP_PASSWORD`：如必须使用密码认证，程序会尝试通过 `sshpass -e` 调用；不推荐
- `BDTOOL_RETURN_SCP_STRICT_HOST_KEY_CHECKING`：默认 `accept-new`

说明：
- 若你的本机不可被 VPS 直接访问，可先建立反向隧道，再把 `HOST/PORT` 指向隧道入口
- 若未设置回传模式，SSH/VPS 会话下会默认把结果保存在 VPS 本地 `~/PT-BDtool-downloads`

## 复制以下命令卸载
```bash
set -euo pipefail
rm -f "$HOME/.local/bin/bdtool" "$HOME/.local/bin/ptbd-start" "$HOME/.local/bin/pt" "$HOME/.local/bin/pts"
rm -rf "$HOME/.local/share/pt-bdtool/PT-BDtool-app"
rm -f /usr/local/bin/bdtool /usr/local/bin/ptbd-start /usr/local/bin/pt /usr/local/bin/pts 2>/dev/null || true
```
