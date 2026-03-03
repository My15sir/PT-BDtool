# PT-BDtool

![Release](https://img.shields.io/github/v/release/My15sir/PT-BDtool)
![CI](https://github.com/My15sir/PT-BDtool/actions/workflows/ci.yml/badge.svg)
![Stars](https://img.shields.io/github/stars/My15sir/PT-BDtool?style=social)

🇬🇧 [English](README.en.md)

## 中文说明

一个用于自动生成 PT 发布素材的 Bash 工具。

### Quick Start

```bash
./bdtool.sh install
./bdtool.sh doctor
./bdtool.sh /path/to/video_or_BDMV_or_iso
./bdtool.sh clean
```

### 输出结构规则

- 所有报告与截图都在：`输出目录/信息/`
- 截图固定：`1.png~6.png`
- `bdinfo.txt` 仅 BDMV/ISO 生成

### 功能 Features

- 自动生成 **MediaInfo**
- 自动生成 **BDInfo（Blu-ray）**
- 自动截取 **视频截图**
- 支持 **目录扫描**
- 支持 **单文件扫描**
- 支持 **并行处理**
- 支持 **本地 / SSH 模式（待翻译）**

### 安装 Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/My15sir/PT-BDtool/main/install.sh)
```

克隆仓库：

```bash
git clone https://github.com/My15sir/PT-BDtool.git
cd PT-BDtool
bash install.sh
```

### 使用 Usage

新入口（推荐，自动输出到 `./bdtool-output`）：

```bash
./bdtool.sh /path/to/videos
```

兼容旧入口（保持可用）：

```bash
./bdtool.sh scan /path/to/videos --out output
```

dry 模式（等价 `--no-shots --no-mediainfo`）：

```bash
./bdtool.sh /path/to/videos --mode dry
```

参数优先级：
- CLI 参数 > 环境变量（`OPT_*`）> 默认值

### 输出示例 Example

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

### BDInfo 规则

- 仅当输入是 **Blu-ray BDMV/ISO** 时执行 BDInfo。
- 报告统一归档到 `信息/bdinfo.txt`。
- 非 BDMV/ISO 输入会跳过 BDInfo（不报错）。

### 依赖 Requirements

需要安装以下工具：

- bash
- ffmpeg
- ffprobe
- mediainfo
- BDInfoCLI-ng（命令名 `BDInfo`，用于 BDMV/ISO）

#### BDInfoCLI 安装

- Linux x64：运行 `install.sh` 会自动安装 BDInfoCLI-ng 预编译包（`BDInfo-linux-x64.tar.gz`）。
- 手动安装来源：`tetrahydroc/BDInfoCLI` Releases。

### 贡献说明

- 本项目为 **纯 AI 生成项目（AI Generated Project）**。
- 目前 **不接受 Issue、Feature Request 或 Pull Request**。
- 如遇问题，请自行排查或咨询 GPT。

### 许可证 License

MIT License
