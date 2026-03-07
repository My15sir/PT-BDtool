# PT-BDtool

This project is AI-generated.
No feedback is accepted.
Please troubleshoot issues by yourself.

## Copy This To Install
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

## Copy This To Start
```bash
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
pt
```

Note: `pt` auto-detects audio/video/disc input types.
Interaction notes:
- Selecting `Scan` in main menu directly starts default full scan (auto-excludes `/proc /sys /dev /run`).
- Input `/` is still supported as a scan shortcut.
- Scan and package-download stages show percent progress up to `100%`.
- Leave download path empty to use the real user desktop (`~/Desktop/PT-BDtool`).
- After item generation, download runs automatically, then cleanup runs automatically.

## VPS Auto Return To Local
The project now exposes a first-class return mode via `BDTOOL_RETURN_MODE`:

- `local`: default; save package locally. In SSH/VPS sessions the default path becomes `~/PT-BDtool-downloads`
- `http`: upload the package to your HTTP receiver with `PUT`
- `scp`: send the package back with `scp`

### Option 1: HTTP return
Recommended when using a reverse tunnel from your local machine:

```bash
export BDTOOL_RETURN_MODE=http
export BDTOOL_RETURN_HTTP_URL='http://127.0.0.1:18080/upload'
pt
```

Legacy compatibility: `BDTOOL_CLIENT_UPLOAD_URL` still works.

### Option 2: SCP return
SSH key auth is recommended:

```bash
export BDTOOL_RETURN_MODE=scp
export BDTOOL_RETURN_SCP_HOST='127.0.0.1'
export BDTOOL_RETURN_SCP_PORT='10022'
export BDTOOL_RETURN_SCP_USER='your-local-user'
export BDTOOL_RETURN_SCP_REMOTE_DIR='/home/your-local-user/Downloads/PT-BDtool'
export BDTOOL_RETURN_SCP_IDENTITY_FILE="$HOME/.ssh/id_ed25519"
pt
```

Optional variables:
- `BDTOOL_RETURN_SCP_PASSWORD`: if password auth is unavoidable, the program will try `sshpass -e`; not recommended
- `BDTOOL_RETURN_SCP_STRICT_HOST_KEY_CHECKING`: defaults to `accept-new`

Notes:
- If the VPS cannot reach your local machine directly, create a reverse tunnel first and point `HOST/PORT` to that tunnel
- Without a return mode, SSH/VPS sessions save the package locally on the VPS under `~/PT-BDtool-downloads`

## Copy This To Uninstall
```bash
set -euo pipefail
rm -f "$HOME/.local/bin/bdtool" "$HOME/.local/bin/ptbd-start" "$HOME/.local/bin/pt" "$HOME/.local/bin/pts"
rm -rf "$HOME/.local/share/pt-bdtool/PT-BDtool-app"
rm -f /usr/local/bin/bdtool /usr/local/bin/ptbd-start /usr/local/bin/pt /usr/local/bin/pts 2>/dev/null || true
```
