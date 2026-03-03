# PT-BDtool

![Release](https://img.shields.io/github/v/release/My15sir/PT-BDtool)
![CI](https://github.com/My15sir/PT-BDtool/actions/workflows/ci.yml/badge.svg)
![Stars](https://img.shields.io/github/stars/My15sir/PT-BDtool?style=social)

一个用于 **自动生成 PT 发布素材** 的 Bash 工具。

可以自动生成：

-   **BDInfo**
-   **MediaInfo**
-   **视频截图（Screenshots）**

适用于整理和生成 PT 站点上传所需信息。

------------------------------------------------------------------------

## 功能 Features

-   自动生成 **MediaInfo**
-   自动生成 **BDInfo（Blu‑ray）**
-   自动截取 **视频截图**
-   支持 **目录扫描**
-   支持 **单文件扫描**
-   支持 **并行处理**
-   支持 **本地 / SSH 模式**

------------------------------------------------------------------------

## 安装 Install

##### 一键安装（推荐）

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/My15sir/PT-BDtool/main/install.sh)
```

##### 克隆仓库：

``` bash
git clone https://github.com/My15sir/PT-BDtool.git
cd PT-BDtool
bash install.sh
```

------------------------------------------------------------------------

## 使用 Usage

新入口（推荐，自动输出到 `./bdtool-output`）：

``` bash
bdtool /path/to/videos
```

扫描单个视频文件（新入口）：

``` bash
bdtool movie.mkv
```

兼容旧入口（保持可用）：

``` bash
bdtool scan /path/to/videos --out output
```

短参数：

``` bash
bdtool movie.mkv -s 6 -j 2
```

说明：截图数量最终固定为 **6 张**，命名严格为 `1.png` 到 `6.png`（`-s/--shots` 仅保留兼容参数）。

dry 模式（等价 `--no-shots --no-mediainfo`）：

``` bash
bdtool movie.mkv --mode dry
```

日志级别：

``` bash
bdtool movie.mkv --log-level debug
bdtool movie.mkv --quiet
```

参数优先级：

- CLI 参数 > 环境变量（`OPT_*`）> 默认值

------------------------------------------------------------------------

## 迁移说明 Migration

- 推荐从旧命令迁移到新入口：
  - `bdtool scan <path> --out output` -> `bdtool <path>`
- 旧 `scan` 子命令仍兼容可用，不会立即移除。
- 若你依赖固定输出目录，请继续显式传 `--out <dir>`。

------------------------------------------------------------------------

## 输出示例 Example

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

BDInfo 规则：

- 仅当输入是 **Blu-ray BDMV/ISO** 时执行 BDInfo，并在 `信息/bdinfo.txt` 归档。
- 非 BDMV/ISO 输入会跳过 BDInfo（不报错）。

------------------------------------------------------------------------

## 依赖 Requirements

需要安装以下工具：

-   bash
-   ffmpeg
-   ffprobe
-   mediainfo
-   BDInfoCLI-ng（命令名 `BDInfo`，用于 BDMV/ISO）

### BDInfoCLI 安装

- Linux x64：运行 `install.sh` 会自动安装 BDInfoCLI-ng 预编译包（`BDInfo-linux-x64.tar.gz`）。
- 手动安装来源：`tetrahydroc/BDInfoCLI` Releases。

------------------------------------------------------------------------

## 贡献说明

本项目为 **纯 AI 生成项目（AI Generated Project）**。

目前 **不接受 Issue、Feature Request 或 Pull Request**。

如遇问题，请自行排查或咨询 GPT。

------------------------------------------------------------------------

## 许可证 License

MIT License
