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

## Copy This To Uninstall
```bash
set -euo pipefail
rm -f "$HOME/.local/bin/bdtool" "$HOME/.local/bin/ptbd-start" "$HOME/.local/bin/pt" "$HOME/.local/bin/pts"
rm -rf "$HOME/.local/share/pt-bdtool/PT-BDtool-app"
rm -f /usr/local/bin/bdtool /usr/local/bin/ptbd-start /usr/local/bin/pt /usr/local/bin/pts 2>/dev/null || true
```
