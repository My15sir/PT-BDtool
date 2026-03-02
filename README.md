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

克隆仓库：

``` bash
git clone https://github.com/My15sir/PT-BDtool.git
cd PT-BDtool
bash install.sh
```

------------------------------------------------------------------------

## 使用 Usage

扫描一个目录：

``` bash
bdtool scan /path/to/videos --out output
```

扫描单个视频文件：

``` bash
bdtool scan movie.mkv --out output
```

关闭截图或 MediaInfo：

``` bash
bdtool scan movie.mkv --out output --no-shots --no-mediainfo
```

------------------------------------------------------------------------

## 输出示例 Example

    output/
    └── 20260302_scan_movie
        └── movie.mkv
            ├── mediainfo/
            │   └── MEDIAINFO.txt
            └── screenshots/
                ├── screenshot_1.png
                ├── screenshot_2.png
                ├── screenshot_3.png
                └── screenshot_4.png

------------------------------------------------------------------------

## 依赖 Requirements

需要安装以下工具：

-   bash
-   ffmpeg
-   ffprobe
-   mediainfo
-   docker（可选，用于 BDInfo）

------------------------------------------------------------------------

## 贡献说明

本项目为 **纯 AI 生成项目（AI Generated Project）**。

目前 **不接受 Issue、Feature Request 或 Pull Request**。

如遇问题，请自行排查或咨询 GPT。

------------------------------------------------------------------------

## 许可证 License

MIT License
