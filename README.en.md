# PT-BDtool

🇨🇳 [中文](README.md)

A Bash tool for generating PT upload materials automatically.

### Quick Start

```bash
bash install.sh
bdtool --help
bdtool doctor
bdtool /path/to/video_or_BDMV_or_iso
bdtool clean
```

### Entrypoints

- `bdtool`: main installed command (interactive menu style)
- `./bdtool.sh`: script-style compatibility entry used in CI and automation

### Output Structure Rules

- All reports and screenshots are stored in: `输出目录/信息/`
- Screenshot files are fixed: `1.png~6.png`
- `bdinfo.txt` is generated only for BDMV/ISO

### Features

- Generate MediaInfo automatically
- Generate BDInfo for Blu-ray sources (BDMV/ISO)
- Capture screenshots automatically
- Directory and single-file scanning
- Parallel processing

### Install

One-line install:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/My15sir/PT-BDtool/main/install.sh)
```

Or clone:

```bash
git clone https://github.com/My15sir/PT-BDtool.git
cd PT-BDtool
bash install.sh
```

### Usage

Preferred entry:

```bash
bdtool /path/to/videos
```

Compatibility entry:

```bash
./bdtool.sh scan /path/to/videos --out output
```

Dry mode:

```bash
./bdtool.sh /path/to/videos --mode dry
```

Version:

```bash
./bdtool.sh --version
```

### Output Example

```text
bdtool-output/
└── 20260303_xxxxxx__scan_xxx
    └── 20260303_xxxxxx__movie.mkv
        └── 信息/
            ├── mediainfo.txt
            ├── 1.png
            ├── 2.png
            ├── 3.png
            ├── 4.png
            ├── 5.png
            └── 6.png
```

### Requirements

- bash
- ffmpeg
- ffprobe
- mediainfo
- BDInfoCLI-ng (`BDInfo` command, for BDMV/ISO)

### BDInfoCLI Install

- On Linux x64, `install.sh` installs the prebuilt package (`BDInfo-linux-x64.tar.gz`) automatically.
- Manual source: `tetrahydroc/BDInfoCLI` Releases.

### Contributing

- This is an AI-generated project.
- Issues / feature requests / pull requests are currently not accepted.

### Test

```bash
./full-test.sh
./codex-run.sh
```

Notes:
- `codex-run.sh` runs tests only by default.
- To enable auto commit/push in that workflow, use `CODEX_RUN_GIT=1 ./codex-run.sh`.

### License

MIT License
