# BrainNet Viewer Web 安装

[English](../en/INSTALLATION.md)

BrainNet Viewer Web 2.0.0在Docker中后台运行，浏览器访问
**http://127.0.0.1:1031/index.html**，无需安装MATLAB或本机Python。
对应镜像为[mingruixia/brainnet-viewer:2.0.0](https://hub.docker.com/r/mingruixia/brainnet-viewer)。

仅在对应版本可用后拉取。公开前可使用提供的、身份明确的本地测试镜像，或按下文从源码构建；
不要用保持不变的公测镜像替代2.0.0。[指定版本安装](RELEASE_INSTALLATION.md)介绍离线加载、
GPU优先启动器、CPU回退及公测升级步骤。

通过Linux服务器IP访问时，请按[服务器部署说明](SERVER_DEPLOYMENT.md)配置HTTPS、
认证与独立浏览器会话，不要直接将本机回环配方开放到局域网。

## 1. 安装并启动 Docker

- **Windows：**安装 [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/)，
  使用 WSL 2 后端和 Linux 容器，然后启动 Docker Desktop。
  配置 WSL 时如要求重启 Windows，请重启后继续。
- **macOS：**根据处理器选择 Apple Silicon 或 Intel 的
  [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/)，安装后打开。
- **Linux：**安装 [Docker Engine](https://docs.docker.com/engine/install/) 和
  [Compose 插件](https://docs.docker.com/compose/install/linux/)。

等待 Docker 显示引擎运行。Windows 打开 PowerShell，macOS/Linux 打开终端，运行：

```sh
docker version
docker compose version
docker info --format '{{.OSType}}/{{.Architecture}}'
```

第一条必须同时显示 Client 和 Server；最后一条应显示 Linux。
Docker 会自动选择适合引擎的 amd64 或 arm64 镜像，Apple Silicon 不需强制选择 amd64。

## 2. 下载 Web 安装包并启动

从对应的[GitHub发行页](https://github.com/mingruixia/BrainNet-Viewer/releases)
或[NITRC](https://www.nitrc.org/projects/bnv/)取得 **BrainNet-Viewer-Web-2.0.0.zip**，
核对SHA256SUMS后解压。若尚未列出该资产，请使用提供的本地镜像或源码构建。

GPU优先启动请使用[指定版本安装](RELEASE_INSTALLATION.md)中的Windows或Linux/macOS启动器。
启动器会实际测试GPU绘图再选择后端；Docker需能向容器分配GPU设备。

使用兼容CPU的Compose配置时，在解压目录打开终端：

```sh
docker compose -f compose.web.release.yml pull
docker compose -f compose.web.release.yml up -d
docker compose -f compose.web.release.yml ps
```

仅在对应镜像公开后执行pull。未公开的本地镜像应将`BNV_IMAGE`设为已核验标签，并跳过pull。
Compose默认不分配GPU，CPU配额默认为1，可按需显式设置`BNV_CPUS`。

浏览器打开 **http://127.0.0.1:1031/index.html**。Docker Desktop需保持运行，终端可关闭。
无法访问时先检查日志，不要重复启动另一个容器。
下方生命周期命令适用于Compose启动；启动器管理的容器应使用[指定版本安装](RELEASE_INSTALLATION.md)
中的操作入口。既有公测安装保留原配方，不混用新版文件。

## 3. 停止、重新打开与更新

停止、重启或更新前，先点击 **Save Scene**，并确认浏览器下载目录中已有 Scene ZIP。

在 Web 安装包的解压目录执行：

```sh
docker compose -f compose.web.release.yml logs --tail 80
docker compose -f compose.web.release.yml stop
docker compose -f compose.web.release.yml start
```

重启正在运行的服务时，将 `start` 改为 `restart`。启动后刷新浏览器。
除非手动停止，容器会随 Docker 重新启动；软件不会自动恢复未保存的会话。

更新时先保存 Scene，取得目标版本的 Compose 文件，再执行 `pull` 和 `up -d`。
随后打开已保存的 Scene 并点击 Apply。需要回退时，请保留对应版本的安装包。

## 4. 文件与资源

**Add Files** 将选择的本机文件上传到软件中，随附的曲面和图谱网络库可直接选用。
**Export Figure** 分别下载图片和溯源 JSON；若只出现一个文件，请检查浏览器的多文件下载权限。
**Save Scene** 下载便携 ZIP，使用 **Open Scene** 打开后点击 **Apply** 恢复。

容器中的上传文件和工作数据是临时数据，请将导出文件与 Scene 保存到本机。
容器停止不会删除已下载的文件。另开浏览器标签页仍连接同一个软件会话，不会创建独立用户。

## 5. 常见问题

| 现象 | 处理方法 |
| --- | --- |
| 找不到 `docker` 命令 | 完成 Docker Desktop 安装，然后重新打开终端。 |
| 无法连接 Docker，或只有 Client 信息 | 启动 Docker Desktop，等待引擎运行，再检查 `docker version`；Windows 确认使用 WSL 2 和 Linux 容器。 |
| `pull access denied` 或 `manifest unknown` | 对照发行页面，检查 Compose 文件中的镜像名与版本是否完全正确。 |
| 下载超时，或代理、DNS、证书错误 | 检查 Docker Desktop 的网络/代理设置及所在网络访问 Docker Hub 的条件。浏览器能上网不代表 Docker 引擎能下载。求助时保留完整错误。 |
| `no matching manifest` | 检查引擎系统与架构，镜像适用于 Linux amd64 或 arm64。 |
| 1031 端口已被占用 | 先确认占用服务。如需换端口，在 Compose 文件旁新建 `.env`，内容为 `BNV_PORT=1035`，执行 `up -d`，访问 http://127.0.0.1:1035/index.html。 |
| 容器运行但网页打不开 | 检查 `ps` 与 `logs --tail 80`，等待初始化，并核对地址及端口。 |
| 容器退出，或大文件上传/导出失败 | 查看日志以及 Docker 可用内存和磁盘空间。配置将内存限制为 8 GiB、CPU 用量限制为 2 核、临时存储限制为 512 MiB；可缩小输入/输出，或明确调整这些限制。 |
| 重启后 Scene 消失 | 打开之前下载的 Scene ZIP，点击 Apply；未保存的工作状态不会自动恢复。 |

下载 ZIP 后可用发行目录中的校验文件核对。镜像已包含运行依赖，正常安装不需要本机
科学计算 Python 环境，也不需要从源码重新构建。

## 部署范围

已发布镜像的配置仅允许本机访问，使用一个共享会话并由 CPU 渲染。
CPU 配额不是主机总核数；拥有显卡不会自动开启容器 GPU 渲染。
共享服务器部署需要身份认证、用户隔离及 HTTPS，不属于本安装配置的适用范围。

## 可选的源码构建

已取得完整仓库的开发者可以本机构建：

```sh
docker compose -f src/python/compose.web.yml up -d --build
```

构建依赖需要联网下载。在 1031 端口上选择源码构建服务或下载镜像中的一种，避免同时启动。

源码镜像使用Python 3.12及固定应用依赖。Compose不分配GPU：Auto进行真实试绘，
没有GPU访问权限时通常选择CPU。源码Compose默认配额为1CPU、8 GiB内存及512 MiB临时存储。
ARM64源码绘图尚未验证，模拟环境中的图形探测失败。使用源码构建的ARM64镜像前，请在目标机器上检查绘图；
已发布的ARM64镜像未替换。

### Windows优先GPU的源码启动

使用Docker Desktop的WSL 2后端、Linux容器及支持的NVIDIA驱动。
先保存Scene并停止占用1031端口的其他服务。在仓库根目录构建独立本机镜像，
然后使用配套PowerShell启动工具：

```powershell
docker build -f src/python/Dockerfile.web -t brainnet-viewer:web-local src/python
powershell -NoProfile -File tools/manage_brainnet_web.ps1 -Action Start -Image brainnet-viewer:web-local -ContainerName brainnet-web-source -Port 1031 -Backend Auto
```

启动器默认配额为Docker引擎可用CPU与8的较小值，可用BNV_CPUS或-CPUs设置有效配额。
Auto先在临时容器中分配GPU并核验实际绘图，GPU启动不可用则启动CPU容器。
`-Backend CPU`明确选择软件绘图；`-Backend GPU`要求硬件绘图，不满足则报错，
不会静默回退。能列出GPU不代表硬件绘图可用。已有容器保留原后端，Stop/Restart
不会重新配置；切换后端请用新的容器名称及空闲端口。

```powershell
powershell -NoProfile -File tools/manage_brainnet_web.ps1 -Action Status -Image brainnet-viewer:web-local -ContainerName brainnet-web-source -Port 1031
powershell -NoProfile -File tools/manage_brainnet_web.ps1 -Action Logs -Image brainnet-viewer:web-local -ContainerName brainnet-web-source -Port 1031
powershell -NoProfile -File tools/manage_brainnet_web.ps1 -Action Stop -Image brainnet-viewer:web-local -ContainerName brainnet-web-source -Port 1031
```

Windows WSL/NVIDIA路径已有本机绘图检查；Linux GPU及其他驱动需各平台独立配置。
macOS Docker不会自动将Mac GPU提供给此Linux镜像。CPU自动回退仅适用于启动阶段；会话中GPU进程崩溃或内存耗尽时，可能需要重新启动。

### 源码Web会话及输入限制

浏览器始终使用相同的回环主机名及端口。源码服务在认证/连接入口拒绝缺失或异源
Origin，通过同源请求获取每次启动的新key。它不提供用户登录，不适合公网多用户服务；
未经独立部署设计，不要暴露到网络或嵌入其他网站的iframe。

仅支持一名受信任用户的私有本机。本机进程可伪造Origin取得key，这不是操作系统
用户认证；不要用于多用户共享主机、JupyterHub或不可信共享网络命名空间。参见
[安全说明](../../../SECURITY.md)。Compose支持`BNV_PORT`（默认1031）、`BNV_CPUS`（1）
及`BNV_MEM`（8g）。WSL容器环境可用`MESA_D3D12_DEFAULT_ADAPTER_NAME`选择显卡，
默认不强制厂商。不要设置内部`BNV_WEB_BOOTSTRAPPED`；启动允许90秒完成图形探测和服务初始化，请根据报告的后端区分硬件与软件绘图。

静止画面使用2倍采样，移动画面降低采样及质量。CPU曲面细节简化仅用于交互期间，
静止、Inspect及导出恢复原几何；输出图片尺寸仍由Export Figure设置。

2.0.0包含用于中文和支持的Unicode图件文字的随附字体，无需在宿主机另行安装字体。不支持的字形会明确报错，不再静默丢失。混合Unicode节点标签使用随附回退字体，标题按实际画布适配，PDF中的回退文字保存为字形轮廓。既有公测镜像不变，请使用对应2.0.0镜像或当前源码。

Scene JSON元数据上限32 MiB，科学文件上传每份32 MiB，Scene ZIP压缩大小64 MiB，
会话文件总量128 MiB。便携Scene保存先暂存并核验资产，再提交新文件名，要求文件系统
支持硬链接。请使用支持的本机文件系统及新的Scene名称，不覆盖已有输出。
重启前保存下载文件。

使用方法见[统一教程](../../tutorials/unified/en/index.md)和[用户手册](../../manual/en/index.md)。
