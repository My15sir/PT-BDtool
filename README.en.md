# PT-BDtool (English)

For bilingual onboarding (CN/EN in one file), see `README.md`.

## Quick Start (Offline Only)

Online one-liner install is deprecated and intentionally blocked:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/My15sir/PT-BDtool/main/install.sh)
```

Use local-repo offline flow instead.

## Copy-Paste Commands

### Normal user

```bash
cd ~
git clone https://github.com/My15sir/PT-BDtool.git
cd PT-BDtool
bash scripts/fetch-deps.sh
bash scripts/build-bundle.sh
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
bdtool
```

### VPS/root (with sudo)

```bash
cd /opt
sudo git clone https://github.com/My15sir/PT-BDtool.git
cd PT-BDtool
sudo bash scripts/fetch-deps.sh
sudo bash scripts/build-bundle.sh
sudo bash install.sh --offline
bdtool
```

## Troubleshooting

### `/dev/fd/... offline dependency missing`

You are running installer via fd/stdin (`bash <(curl ...)`).  
Clone the repo and run `bash install.sh --offline` locally.

### `scripts/*.sh: No such file or directory`

You are not in repo root. Run:

```bash
cd ~/PT-BDtool
ls scripts
```

### `bdtool: command not found`

Add local bin to PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
bdtool --help
```

### Startup abnormal or scan finds nothing

Fallback:

```bash
ptbd-start
```

Supported scan targets:
- videos: `*.mkv *.mp4 *.avi *.mov *.ts *.m2ts *.wmv *.webm *.mpg *.mpeg`
- Blu-ray: `BDMV` directory
- image: `*.iso`

If you entered executable path like `/opt/PT-BDtool/bdtool`, use a media directory instead.
