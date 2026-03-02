# BDTool

本工具用于自动处理 Blu-ray BDMV 或普通视频文件。

功能：

- 自动识别 BDMV 原盘结构
- BDMV 使用 BDInfo 生成报告
- 普通视频使用 MediaInfo
- 自动生成随机截图
- 支持本地路径
- 支持远程 VPS
- 可选自动拉回结果
- 可选自动清理远端文件

## 规划命令

本地：

./bdtool.sh --local /path --out ./out
./bdtool.sh --ssh root@ip:/path --out ./out --pull

终端返回提示符后说明文件写入完成。

请确认终端是否已经返回到：

