# PT-BDtool

![GitHub stars](https://img.shields.io/github/stars/My15sir/PT-BDtool?style=social)
![GitHub last commit](https://img.shields.io/github/last-commit/My15sir/PT-BDtool)
![License](https://img.shields.io/badge/license-MIT-blue)
![Platform](https://img.shields.io/badge/platform-Linux-green)

PT-BDtool 是一个用于 **PT（Private Tracker）发布准备** 的自动化 CLI 工具。

它可以自动为 **Blu‑ray BDMV 原盘** 或 **普通视频文件** 生成：

- BDInfo 报告
- MediaInfo 报告
- 随机截图

适合运行在：

- VPS
- Linux服务器
- NAS
- 本地电脑

---

# 功能特点

- 自动识别 **Blu‑ray BDMV 原盘结构**
- 自动寻找 **最长 MPLS 播放列表**
- 自动生成 **BDInfo 报告**
- 自动生成 **MediaInfo 报告**
- 自动生成 **4 张随机截图**
- 自动识别 **BDMV / 普通视频**
- 支持 **批量扫描**
- 支持 **一键安装**
- 支持 **自动更新**
- 适合 **PT发布工作流**

---

# 一键安装

推荐使用一键安装：

```bash
bash <(wget -qO- https://raw.githubusercontent.com/My15sir/PT-BDtool/main/install.sh) -k
```

安装脚本会自动安装以下依赖：

- ffmpeg
- mediainfo
- docker
- bdtool

安装完成后运行：

```bash
bdtool doctor
```

检查环境是否正常。

---

# CLI 命令

## 扫描目录

```bash
bdtool scan /路径 --out 输出目录
```

示例：

```bash
bdtool scan /downloads --out /root/out
```

---

## 检查环境

```bash
bdtool doctor
```

示例输出：

```
== doctor ==
OK: ffmpeg
OK: mediainfo
OK: docker
OK: wget
OK: curl
```

---

## 更新工具

```bash
bdtool update
```

该命令会从 GitHub 自动更新到最新版本。

---

# 输出示例

```
out/
 └ 20260302_173000_scan_downloads/
    ├ BDINFO.bd.txt
    ├ 截图_1.png
    ├ 截图_2.png
    ├ 截图_3.png
    └ 截图_4.png
```

---

# 支持输入类型

## Blu‑ray BDMV

自动执行：

- 检测 BDMV 结构
- 查找最长 MPLS
- 生成 BDInfo 报告
- 从主视频流生成截图

---

## 普通视频文件

支持格式：

```
mkv
mp4
m2ts
ts
avi
mov
wmv
webm
mpg
mpeg
```

自动生成：

- MediaInfo 报告
- 随机截图

---

# 项目结构

```
PT-BDtool
 ├ install.sh
 ├ bdtool.sh
 └ README.md
```

---

# 依赖项目

感谢以下优秀开源项目：

### FFmpeg

https://ffmpeg.org/

视频解码与截图生成。

---

### MediaInfo

https://mediaarea.net/en/MediaInfo

媒体信息提取。

---

### BDInfo CLI

https://github.com/fr3akyphantom/bdinfocli-ng

用于 Blu‑ray 播放列表分析。

Docker 镜像：

```
fr3akyphantom/bdinfocli-ng
```

---

### Docker

https://www.docker.com/

用于运行 BDInfo CLI 容器。

---

# 贡献

本项目为 **纯 AI 生成项目（AI Generated Project）**。

目前不接受 Issue、Feature Request 或 Pull Request。

如果在使用过程中遇到问题，请直接询问 GPT或其他AI 进行排查、解决。

感谢理解。

---

# License

MIT License

---

# 作者

Maintained by:

My15sir

GitHub:

https://github.com/My15sir
