# 指定版本的Docker安装

[English](../en/RELEASE_INSTALLATION.md) · [Linux服务器](SERVER_DEPLOYMENT.md)

本配方面向2.0.0，已发布的2.0.0-beta.1镜像保持不变。
正式镜像公开前，使用`docker load --input IMAGE_ARCHIVE.tar`载入候选，
先核对档案校验值、架构及image ID；不要用旧公测镜像验证更新版本。
Compose通过`BNV_IMAGE`指定载入标签，启动脚本分别用Windows的`-Image`
或Linux/macOS的`--image`。本地image ID与仓库manifest digest不可混用。

## 取得并启动镜像

安装并启动Docker，使用Linux容器。检查`docker version`及`docker compose version`。
按引擎架构使用amd64或arm64，Apple Silicon不要强制amd64。
2.0.0发布后，解压对应Web ZIP，在包含`compose.web.release.yml`的目录运行：

```sh
docker compose -f compose.web.release.yml pull
```

GPU优先启动，在Windows PowerShell运行：

```powershell
powershell -NoProfile -File start_web.ps1 -Action Start -Backend Auto
powershell -NoProfile -File start_web.ps1 -Action Status
powershell -NoProfile -File start_web.ps1 -Action Logs
powershell -NoProfile -File start_web.ps1 -Action Stop
```

Linux或macOS运行：

```sh
sh start_web.sh
sh start_web.sh --action status
sh start_web.sh --action logs
sh start_web.sh --action stop
```

打开 **http://127.0.0.1:1031/index.html**。首次启动需初始化绘图，
请先查看健康状态和日志，不要重复启动。关闭终端后服务继续运行。
停止前先Save Scene，工作区上传内容为临时文件。

Auto先向临时探测容器分配NVIDIA GPU并实际绘制一帧；设备分配或绘图失败时，
应用容器不再请求GPU，使用CPU。Windows需要Docker Desktop、WSL 2及适配的NVIDIA支持；
Linux需要管理员已配置的兼容驱动及NVIDIA Container Toolkit。
脚本不会安装或修改这些组件。Apple Silicon Docker使用CPU，本镜像不提供Metal访问。

`-Backend CPU`／`--backend cpu`强制CPU；`-Backend GPU`／`--backend gpu`
要求硬件绘图，失败时停止，不静默改用CPU。已有容器保留原后端；改变后端请使用新
`-ContainerName`／`--name`及空闲`-Port`／`--port`。
身份或端口不符时拒绝操作。脚本不拉取镜像、不删除容器。
启动回退不保证会话中驱动崩溃或显存耗尽后的恢复。

源码仓库中的入口为`tools/manage_brainnet_web.ps1`及`tools/start_web.sh`；
ZIP中脚本名是同一实现的别名。源码构建或离线镜像须显式指定标签，
不依赖默认`mingruixia/brainnet-viewer:2.0.0`。

启动器读取Docker引擎的可用CPU数，包括Docker Desktop虚拟机的CPU限制，
默认配额取该值与8的较小值。可设置`BNV_CPUS`，或使用`-CPUs '1.5'`／`--cpus 1.5`覆盖，
命令行优先；数值须在0.01至引擎可用CPU数之间。非法配额或引擎查询失败会在GPU探测前停止，
不会误报为GPU不可用。探测及应用容器使用同一配额。
已有容器的CPU/后端不随Start/Restart改变，需要变更时使用新容器。

## 从2.0.0-beta.1升级

1. 保留旧版文件和镜像。在旧版中点击 **Save Scene**，确认ZIP已下载。
   新Web包解压到另一目录，不覆盖公测文件夹，不丢弃已保存的Scene。
2. 识别旧服务及占用端口。在原公测包目录中核对项目、镜像和绑定，
   再仅停止确认的旧服务：

```sh
docker compose -f compose.web.release.yml -p brainnet-viewer-beta ps
docker compose -f compose.web.release.yml -p brainnet-viewer-beta stop
```

   命令必须使用**旧目录中的**Compose文件。stop保留容器和镜像，便于回退。
   如果旧版使用其他方式启动，先查看`docker ps`，再用
   `docker stop VERIFIED_OLD_CONTAINER`停止已核实的那个容器；请替换占位名称。
   不停止其他服务，不进行全局清理。
3. 在新目录启动新版本。新Compose使用不同项目名；启动器创建的旧容器即使已停止，
   仍保留其名称，因此请使用新名称，例如Windows的`-ContainerName brainnet-web-2`
   或Linux/macOS的`--name brainnet-web-2`。旧服务停止后才能使用1031端口。
   需要两版并行时，还要选择空闲端口，例如`-Port 1035`或`--port 1035`，
   并打开对应浏览器端口。只改容器名称不能释放已占用的端口。
4. 打开已下载的Scene，点击 **Apply**，检查数据和设置是否恢复。
   需要回退时先保存新工作，仅停止已核实的新服务，再从原目录启动旧公测服务。
   不应为绕过身份检查而删除旧容器或镜像。

## 不分配GPU的Compose方式

也可不用启动脚本，改用：

```sh
docker compose -f compose.web.release.yml up -d
docker compose -f compose.web.release.yml ps
docker compose -f compose.web.release.yml logs --tail 80
docker compose -f compose.web.release.yml stop
```

不要与启动脚本在同一端口同时运行。Compose设置应用内部Auto，但不分配GPU，
因此通常使用CPU。Compose默认配额为1CPU，以兼容小型引擎；可通过`BNV_CPUS`
设置不超过引擎可用CPU数的配额，服务器可按并发需求适当增加。
`BNV_RENDER_BACKEND=cpu`显式指定CPU，`BNV_PORT`改变主机端口。
源码仓库的Compose路径加`src/python/`前缀。两种本机入口均只绑定回环地址，
使用一个共享工作区。Export Figure分别下载图片及JSON侧车，Save Scene下载ZIP。

## 通过指定镜像部署Linux服务器

按[服务器准备说明](SERVER_DEPLOYMENT.md)取得含服务器IP且客户端信任的证书、私钥，
以及UID 10001可读的密码文件。将其放在发布Compose旁的`.server-secrets/`，
或设置`BNV_SERVER_SECRETS_DIR`为私有目录。密钥不得写入镜像或仓库。
在Linux服务器运行：

```sh
export BNV_SERVER_ORIGIN=https://192.168.1.10:1031
docker compose -f compose.web.server.release.yml up -d
docker compose -f compose.web.server.release.yml ps
docker compose -f compose.web.server.release.yml logs --tail 80
```

替换为证书中的服务器IP。源码仓库使用`src/python/compose.web.server.release.yml`，
密钥目录默认位于该文件旁。本配方直接使用指定镜像，不要求ZIP另有Dockerfile或源码；
离线候选先设置`BNV_IMAGE`。

每个登录的浏览器会话有独立进程；共享cookie的标签页属于同一会话，
其他配置文件或隐私窗口可建立独立工作区。默认四会话共享有界容器资源。
此方式适用于可信局域网HTTPS服务，不面向匿名互联网。
服务器配方不分配GPU，需按硬件另行配置；worker内部Auto不能授予设备权限。
CPU及实际GPU验证分别记录，来源、凭据及资源规则继续遵循服务器指南。
