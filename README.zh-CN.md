# BrainNet Viewer 2.0

[English](README.md) · [统一手册](docs/manual/en/index.md) · [统一教程（英文）](docs/tutorials/unified/en/index.md)

BrainNet Viewer 用于显示脑曲面、网络、曲面映射和图谱 ROI。
2.0.0-beta.1 提供 MATLAB 桌面版、独立的 Python 桌面版和由 Docker 运行的 Web 版。

默认分支包含公测发布后的维护更新，下载包和 Docker Hub 的 `2.0.0-beta.1`
镜像仍保留发布时的代码。如需使用维护更新，请按安装指南从源码安装。
具体变更见[更新说明](CHANGELOG.zh-CN.md)。

## 安装与启动

- MATLAB：安装并激活MATLAB，Current Folder切换到仓库根目录，
  运行 `app = BrainNetViewer;`。不要递归加入其他BrainNet Viewer版本。
  参见[入门指南](docs/documentation/Getting_Started.zh-CN.md)。
- Python桌面版：按[安装指南](docs/python/zh-CN/INSTALLATION.md)安装wheel及
  desktop附加依赖，运行 `python -m brainnet_viewer`，不需要MATLAB。
- Web版：按[Docker说明](docs/web/zh-CN/INSTALLATION.md)后台启动容器，
  浏览器打开 http://127.0.0.1:1031/index.html。
  下载Web安装包，按指南拉取并启动镜像即可，无需源码构建。
  镜像：[mingruixia/brainnet-viewer:2.0.0-beta.1](https://hub.docker.com/r/mingruixia/brainnet-viewer)。

## 操作流程

在 **Data Sources** 中选择输入文件，在 **Visualization Settings** 中调整显示设置，
点击 **Apply** 绘图。随后可操作所选视图，或通过 **Export Figure** 保存图片。
**Save Scene** 保存输入与设置，便于再次打开；Preset 只保存显示设置，供其他数据复用。
统一手册和教程介绍文件格式、科学解释、导出方法及各版本的差异。

安装包附带曲面库、图谱网络示例和教程数据。[AtlasNetworks](src/matlab/BrainNetViewer/Data/ExampleFiles/AtlasNetworks/README.md)
保留AAL90，并提供14套GroupFC配对文件，包含AAL116、Schaefer1000和Brainnetome246。
AAL90体积和顶点标签位于源码/MATLAB包根目录的`resources/atlases/AAL90/`；
Python/Docker资源库中对应`atlases/AAL90/`。Inspect基于MNI类空间查询
AAL/Brodmann；使用个人数据前确认配准与坐标对应。界面为英文，
软件不限于人脑数据。Web 版使用一个共享会话，适合受信任用户在个人电脑上运行。
源码启动时会测试 GPU 绘图，不可用时使用 CPU；已发布镜像使用 CPU。
停止或更新容器前，请保存便携 Scene。

本地服务会检查浏览器请求，但不提供操作系统用户认证。本机进程可以伪造请求头，
因此不适合多用户共享主机或公网部署。参见[安全说明](SECURITY.md)。

## 源码构建

Python 打包和 Docker 文件位于 `src/python`。请创建独立环境，并安装 `desktop` 或 `web` 附加依赖；
可运行 `python -m pip wheel --no-deps ./src/python` 构建wheel。
[Docker指南](docs/web/zh-CN/INSTALLATION.md)提供源码构建命令，默认端口1031。

## 引用与支持

Xia M, Wang J, He Y (2013). BrainNet Viewer: A Network Visualization Tool for
Human Brain Connectomics. PLoS ONE 8: e68910.
https://doi.org/10.1371/journal.pone.0068910

[GitHub](https://github.com/mingruixia/BrainNet-Viewer) ·
[NITRC](https://www.nitrc.org/projects/bnv/) · [更新说明](CHANGELOG.zh-CN.md)

联系人Mingrui Xia：mxia@bnu.edu.cn；mingruixia@gmail.com。
代码使用[GPL-3.0-or-later](LICENSE)，请保留代码及资源说明。
