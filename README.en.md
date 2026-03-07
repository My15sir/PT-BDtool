# PT-BDtool

PT-BDtool is a media info packaging tool.

It can process:
- video files
- audio files
- Blu-ray `BDMV` folders
- Blu-ray `ISO` images

After processing, it generates a ready-to-use info package, for example:
- Video: `mediainfo.txt` + `1.png` to `6.png`
- Audio: `mediainfo.txt` + `频谱图.png`
- Disc/ISO: `BDInfo.txt` + `1.png` to `6.png`

If you only want the quickest way to use it, start with **3-minute quick start** below.

## 3-Minute Quick Start

### Step 1: Install
Run this inside the project directory:

```bash
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
```

Check that installation worked:

```bash
pt --help
```

### Step 2: Start
The simplest way:

```bash
pt
```

### Step 3: Follow the menu
Inside the menu:

1. Type `1` to start scanning
2. Wait for scan to finish
3. Enter the item number you want to process
4. Wait for generation and packaging
5. Go to the shown output path and get your package

## The 3 Most Common Ways To Use It

### Option 1: Use it on your local machine
If you run it on your own computer:

```bash
export PATH="$HOME/.local/bin:$PATH"
pt
```

The result is saved to your desktop by default.

### Option 2: Use it on a VPS and keep the result on the VPS
This is the simplest and most reliable VPS workflow:

```bash
export PATH="$HOME/.local/bin:$PATH"
export BDTOOL_DOWNLOAD_DIR="$HOME/PT-BDtool-downloads"
pt
```

After processing, the package will be stored in:

```bash
$HOME/PT-BDtool-downloads
```

Then download it from your local machine:

```bash
scp user@your-vps-ip:$HOME/PT-BDtool-downloads/*.zip .
```

If zip is not available, the file may be `tar.gz` instead.

### Option 3: Skip the menu and process one file directly
If you already know the file path, direct CLI is easier:

```bash
bdtool /path/to/movie.mp4 --out /path/to/output
```

Example:

```bash
bdtool ~/Videos/test.mp4 --out ~/PT-output
```

## Best Practice For VPS Users

If you are on a VPS, this is the recommended starting point:

```bash
bash install.sh --offline
export PATH="$HOME/.local/bin:$PATH"
export BDTOOL_DOWNLOAD_DIR="$HOME/PT-BDtool-downloads"
pt
```

Why this is recommended:
- no desktop environment required
- no auto-return setup required
- fewer moving parts
- easier troubleshooting

## If You Want Automatic Return To Your Local Machine

This is an advanced feature, but it is now officially supported.

Use `BDTOOL_RETURN_MODE` to choose the mode:

- `local`: save on the current machine
- `http`: upload automatically to your HTTP receiver
- `scp`: send back automatically with `scp`

### Option A: HTTP auto-return
Best if you already have a receiver or use a reverse tunnel.

```bash
export BDTOOL_RETURN_MODE=http
export BDTOOL_RETURN_HTTP_URL='http://127.0.0.1:18080/upload'
pt
```

Legacy variable still supported:

```bash
BDTOOL_CLIENT_UPLOAD_URL
```

### Option B: SCP auto-return
SSH key authentication is recommended.

```bash
export BDTOOL_RETURN_MODE=scp
export BDTOOL_RETURN_SCP_HOST='127.0.0.1'
export BDTOOL_RETURN_SCP_PORT='10022'
export BDTOOL_RETURN_SCP_USER='your-local-user'
export BDTOOL_RETURN_SCP_REMOTE_DIR='/home/your-local-user/Downloads/PT-BDtool'
export BDTOOL_RETURN_SCP_IDENTITY_FILE="$HOME/.ssh/id_ed25519"
pt
```

Optional:
- `BDTOOL_RETURN_SCP_PASSWORD`: only if password auth is unavoidable; the tool will try `sshpass -e`
- `BDTOOL_RETURN_SCP_STRICT_HOST_KEY_CHECKING`: default is `accept-new`

Notes:
- If the VPS cannot reach your local machine directly, create a reverse tunnel first
- If you are not sure how to configure this, use the “save on VPS first” workflow above

## Useful Commands

### Show help
```bash
bdtool --help
```

### Check dependencies
```bash
bdtool doctor
```

### Check install status
```bash
bdtool status
```

### Clean output directory
```bash
bdtool clean
```

## Direct CLI Examples

### Process one video
```bash
bdtool /data/movie.mkv --out /data/output
```

### Process one audio file
```bash
bdtool /data/song.flac --out /data/output
```

### Process a whole directory
```bash
bdtool /data/media-dir --out /data/output
```

### Dry run only
```bash
bdtool /data/movie.mkv --mode dry --out /data/output
```

### Enable debug logs
```bash
bdtool /data/movie.mkv --log-level debug --out /data/output
```

## What The Menu Does

When you run `pt`, it generally does this:

1. scan media files
2. list candidates
3. let you choose an item
4. generate info files and screenshots
5. package the result
6. save locally or return automatically
7. clean temporary generated files by default

## What You Usually Get

### Video
- `mediainfo.txt`
- `1.png`
- `2.png`
- `3.png`
- `4.png`
- `5.png`
- `6.png`

### Audio
- `mediainfo.txt`
- `频谱图.png`

### Disc / ISO
- `BDInfo.txt`
- `1.png`
- `2.png`
- `3.png`
- `4.png`
- `5.png`
- `6.png`

## Uninstall

```bash
set -euo pipefail
rm -f "$HOME/.local/bin/bdtool" "$HOME/.local/bin/ptbd-start" "$HOME/.local/bin/pt" "$HOME/.local/bin/pts"
rm -rf "$HOME/.local/share/pt-bdtool/PT-BDtool-app"
rm -f /usr/local/bin/bdtool /usr/local/bin/ptbd-start /usr/local/bin/pt /usr/local/bin/pts 2>/dev/null || true
```
