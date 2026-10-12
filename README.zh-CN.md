# BrainNet Viewer 2.0

[English](README.md) · [统一手册](docs/manual/en/index.md) · [统一教程（英文）](docs/tutorials/unified/en/index.md)

BrainNet Viewer 2.0.0-beta.1用于曲面、节点、连边、曲面映射与图谱ROI可视化。
提供MATLAB桌面版、Python桌面版和Docker/Web版。开发者：Mingrui Xia。

默认分支包含公测发布后的维护更新。下载包及Docker Hub的`2.0.0-beta.1`
镜像仍对应原公测版，不包含这些较新的源码修改。更新内容见[更新说明](CHANGELOG.zh-CN.md)，
使用更新代码请按安装指南的源码安装部分操作。

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

Data Sources读取文件 → Visualization Settings配置 → Apply绘图 →
操作所选子图 → 保存/导出。Scene保存输入和设置；Preset保存显示配置。
科学输入、版本差异及导出设置参见统一手册和教程。

包含曲面库、图谱网络示例和真实教程数据。[AtlasNetworks](src/matlab/BrainNetViewer/Data/ExampleFiles/AtlasNetworks/README.md)
保留AAL90，并提供14套GroupFC配对文件，包含AAL116、Schaefer1000和Brainnetome246。
AAL90体积和顶点标签位于源码/MATLAB包根目录的`resources/atlases/AAL90/`；
Python/Docker资源库中对应`atlases/AAL90/`。Inspect基于MNI类空间查询
AAL/Brodmann；使用个人数据前确认配准与坐标对应。界面为英文，
软件不限于人脑数据。Web支持本机单一共享会话；源码构建在可用时优先使用
经过实际试绘核验的GPU，否则使用CPU，已发布镜像使用CPU。
停止或更新容器前保存便携Scene。

## 源码构建

Python打包和Docker文件位于src/python。独立开发环境选择desktop或web附加依赖；
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
