# BrainNet Viewer Web — 本机 Docker 安装

Web 应用在 Docker 后台运行，通过浏览器使用，默认主机端口为 **1031**。
浏览器所在电脑无需安装 MATLAB 或桌面 Python 环境。

当前候选仅支持**本机单用户、一个共享会话**，不要发布到局域网、互联网或隧道。
认证、用户隔离、TLS 和远程服务器验收需要另行开发。容器目前采用软件渲染；
主机有显卡不代表 Docker 已使用 GPU 加速。

## 前提

- 已正常运行、配置为 Linux 容器的 Docker 引擎。
- 下述源码构建方式需要 Docker Compose v2。
- 完整项目源码，包括 `src/python`、Dockerfile 和随附资源。
- 首次构建需要联网。已构建镜像可以传输后直接加载，不必重建；镜像分发另行安排。

先执行 `docker version`。如无法连接引擎，请启动引擎并解决访问权限问题，
不要修改应用依赖的固定版本。

## 从源码构建并启动

在 Windows、macOS 或 Linux 的项目根目录执行：

```sh
docker compose -f src/python/compose.web.yml config
docker compose -f src/python/compose.web.yml up -d --build
```

浏览器打开 **http://127.0.0.1:1031/index.html**。Docker 引擎需保持运行；
关闭终端不会停止后台容器。
当前开发源码构建在容器模式关闭浏览器空闲退出计时，后台服务保持可用，直至明确停止。
此前构建的镜像可能仍保留依赖库默认的五分钟空闲退出行为。

```sh
docker compose -f src/python/compose.web.yml ps
docker compose -f src/python/compose.web.yml logs --tail 60
docker compose -f src/python/compose.web.yml stop
docker compose -f src/python/compose.web.yml start
docker compose -f src/python/compose.web.yml restart
```

始终使用同一项目及 Compose 文件。`start` 只启动已创建、已停止的容器，不会新建或构建。
启动/重启后刷新浏览器。更新源码前先保存会话，再执行 `up -d --build`。
不要与另一个占用 1031 端口的服务同时运行。

## 可选 Windows 管理脚本

在项目根目录先构建一次指定名称的镜像：

```powershell
docker build -f src/python/Dockerfile.web -t brainnet-viewer:web-local src/python
```

随后可用脚本替代 Compose，同一服务不要混用两种管理方式：

```powershell
.\tools\manage_brainnet_web.ps1 -Action Start
.\tools\manage_brainnet_web.ps1 -Action Status
.\tools\manage_brainnet_web.ps1 -Action Logs
.\tools\manage_brainnet_web.ps1 -Action Stop
.\tools\manage_brainnet_web.ps1 -Action Start
.\tools\manage_brainnet_web.ps1 -Action Restart
```

默认镜像为 `brainnet-viewer:web-local`，容器为 `brainnet-web`，主机端口为 1031。
可通过 `-Image`、`-ContainerName`、`-Port` 指定其他候选或空闲的本机端口；
容器内部端口仍为 1031。脚本操作已有容器前核对准确镜像身份和回环端口绑定，
不会自动替换或删除容器。重复 Start 不会创建第二份，启动/重启最多等待 30 秒检查 HTTP 就绪。
如 PowerShell 阻止执行脚本，请遵循单位脚本策略，或直接使用上方 Docker 命令，
不要降低系统安全策略。

## 会话与文件保存

**停止、重启、更新或删除容器前，先 Save Scene 并确认浏览器已下载文件。**
设置、相机、上传及工具生成文件属于 `/tmp` 中的临时会话，不是持久项目文件。
重建或重启进程不会自动恢复场景；关闭/刷新浏览器也不是建立独立会话的可靠方式。

- Add Files 将本机输入上传至容器；输入路径文字不等于访问服务器文件系统。
- Export Figure 分别下载图片与 `.provenance.json`，不打包 ZIP。
  保存位置、多文件下载许可和重名处理由浏览器控制。
- Save Scene 下载可移植 Scene ZIP；通过 Open Scene、Apply 恢复，
  不会恢复另一个用户正在使用的浏览器会话。
- 已下载到本机的文件不会因容器停止/重启而被删除。

## 限额、排错与验证范围

配套配置采用非 root、只读根目录、512 MiB 临时文件系统、8 GiB 内存、
8 CPU 配额及 256 PID 限额。显示的主机逻辑 CPU 数不代表容器 CPU 配额；
内存显示支持 cgroup v1/v2。软件渲染属预期行为，GPU 库存与实际渲染设备分别报告。

如 1031 被占用，请先识别占用者，不要停止无关进程。
可用脚本选择空闲的回环主机端口，或明确修改 Compose 端口映射，同时保留 `127.0.0.1`。
页面打不开时检查状态、日志、引擎和端口，再刷新浏览器；就绪超时不应再启动竞争服务。

上传/导出超限或临时空间不足时，先保存可用结果，再使用更小输入或输出尺寸。
保存可移植 Scene 后再重启，不要悄悄放宽依赖或配额。

当前候选已做 Windows 主机上的 Linux 容器生命周期、渲染和导出专项；
不代表 macOS Docker、硬件 GPU、多人服务或三版本全功能验收。
共享科学操作见[统一教程](../../tutorials/unified/en/index.md)和
[手册](../../manual/en/index.md)，Web 差异见开发说明 (repository reference)。
