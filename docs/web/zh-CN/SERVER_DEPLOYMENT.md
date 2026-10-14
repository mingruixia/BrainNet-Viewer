# BrainNet Viewer Linux 局域网服务器部署

[English](../en/SERVER_DEPLOYMENT.md) · [本机安装](INSTALLATION.md)

服务器模式让团队成员通过 Linux 服务器的 IP 使用 BrainNet Viewer。每个已登录的
浏览器会话使用独立应用进程，分别保存上传文件、设置和相机。同一客户端 IP 下的
不同浏览器仍相互独立。同一浏览器配置下的多个标签页共享会话；如需另一个工作区，
请使用不同的浏览器配置或隐私浏览会话。

服务器模式需要使用当前主线源码构建。Docker Hub 上已有的 `2.0.0-beta.1` 镜像
不包含该功能。原本机 Compose 配置仍仅开放回环地址的 1031 端口，并使用单个共享会话。

## 准备服务器

在 Linux 上安装 [Docker Engine](https://docs.docker.com/engine/install/) 和
[Compose 插件](https://docs.docker.com/compose/install/linux/)，取得完整仓库，
在仓库根目录打开终端。为服务器分配稳定 IP，通过主机或单位防火墙，仅允许团队
所在局域网访问 TCP 1031 端口。不要将此服务直接暴露到互联网。

服务器要求 HTTPS 和访问密码。请管理员提供证书及匹配的私钥，证书的 Subject
Alternative Name 必须包含服务器 IP，并在客户端计算机上获得信任。不要跳过
证书告警，也不要通过明文 HTTP 传输密码。

新建 `src/python/.server-secrets/`，放入以下文件：

| 文件 | 内容 |
| --- | --- |
| `server.crt` | PEM 格式证书；需要时包含中间证书链 |
| `server.key` | 与证书匹配的 PEM 私钥 |
| `access_password.txt` | 一行随机团队访问密码，长度为 16–256 个 UTF-8 字节 |

此目录已排除在 Git 和 Docker 构建之外，不要提交其中的文件。原始文件只应允许
管理员和 Docker 服务读取。应用以 UID 10001 运行，只读挂载的文件需允许该 UID
读取。在原生 Linux 上，管理员可将这些文件的属主设为 UID 10001、权限设为 0400，
父目录保持私有；操作前请核对本机属主及 Docker rootless 的映射。不要将私钥设为
所有用户可读。

如管理员将文件保存在别处，可将 `BNV_SERVER_SECRETS_DIR` 设为该目录的绝对路径。
文件仅在启动时挂载，不进入镜像。修改访问密码后需重启服务器，重启会结束全部会话。

## 构建与启动

将示例地址替换为证书对应的服务器 IP：

```sh
export BNV_SERVER_ORIGIN=https://192.168.1.10:1031
docker compose -f src/python/compose.web.server.yml up -d --build
docker compose -f src/python/compose.web.server.yml ps
docker compose -f src/python/compose.web.server.yml logs --tail 80
```

客户端打开 **https://192.168.1.10:1031/index.html**，输入团队访问密码。
新会话首次启动应用时，图形初始化可能需要最多 90 秒。刷新页面会复用原会话，
不会重新分配进程。

必须使用配置中指定的完整地址，其他 IP、别名、主机名或端口会被拒绝。如需改变
主机端口，同时修改 `BNV_PORT` 和 `BNV_SERVER_ORIGIN` 中的端口；容器内部端口
仍为 1031。本配置由网关直接处理 TLS，不信任转发的主机名或协议请求头。
如使用终止 TLS 的反向代理，需要另行配置，不能仅添加这些请求头。

## 会话生命周期与资源

默认最多允许四个浏览器会话。登录后占用一个名额，首次请求应用页面时启动对应
进程。名额已满时，新登录显示容量提示，不影响已有用户。启动失败或意外退出的
进程会被清理，用户需重新登录以建立新工作区。

关闭全部应用标签页后，会话不再保持连接。断开连接且无请求满 30 分钟后，服务器
清理对应进程及临时文件；保持连接的标签页会保留会话。如需立即释放，打开
`https://服务器IP:1031/_bnv/session`，点击 **Sign out and end session**。
退出前请先保存 Scene。

| 变量 | 默认值 | 含义 |
| --- | --- | --- |
| `BNV_MAX_SESSIONS` | `4` | 最多已登录会话数，可设 1–32 |
| `BNV_IDLE_SECONDS` | `1800` | 断开连接后的保留秒数，可设 30–86400 |
| `BNV_WORKER_THREADS` | `2` | 每个进程的科学计算库线程设置，可设 1–64 |
| `BNV_MEM` | `16g` | 整个容器的内存上限 |
| `BNV_CPUS` | `8` | 整个容器的 CPU 配额 |
| `BNV_TMP_SIZE` | `2g` | 全部会话共享的临时存储上限 |
| `BNV_RENDER_BACKEND` | `auto` | 可选 `auto`、`cpu`、`gpu` |
| `BNV_SERVER_BIND` | `0.0.0.0` | 主机接收连接的接口 |
| `BNV_PORT` | `1031` | 主机端口 |

容器上限由全部进程共同使用，不是每个用户独享的配额。线程设置也不是单进程
CPU 或内存的硬限制。请从较低并发数开始，用实际数据评估资源占用；内存、临时
存储或显存不足时降低并发。独立进程隔离的是应用状态，不是恶意操作系统用户。
本模式面向可信团队成员，不适用于匿名公网服务。共享密码用于控制访问，不提供
实名账号、角色权限、单个成员撤权或单位身份认证系统。

## CPU 与 GPU

每个进程在独立探测进程中验证绘图后端。`auto` 在硬件绘图可用时使用 GPU，探测
无法使用硬件时回退 CPU。默认服务器配置不分配 GPU 设备，因此通常使用软件绘图。
选择 `gpu` 则要求实际硬件绘图；不可用时启动失败，不会静默改用 CPU。

原生 Linux GPU 绘图需要兼容的驱动及容器设备分配。NVIDIA 环境还需要
[NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)。
请管理员按服务器硬件配置设备权限，不要直接套用 Windows WSL 设置。各进程共用
所分配的 GPU 和显存。启动时的自动回退不保证能从会话中的显存不足或驱动故障恢复。

## 文件与维护

Add Files 从客户端上传到本会话。Save Scene 将可携带 ZIP 下载到客户端；Export
Figure 分别下载图片和溯源 JSON，仍受浏览器下载权限影响。临时上传不是服务器
归档，请在退出、停服或更新之前保存下载的 Scene。

```sh
docker compose -f src/python/compose.web.server.yml stop
docker compose -f src/python/compose.web.server.yml start
```

执行这些命令时，保持 `BNV_SERVER_ORIGIN` 等环境变量有效，也可将非秘密设置
保存在私有环境文件中。访问密码和 TLS 私钥应保存在挂载文件，不要放入命令参数。
更新源码后，先保存全部活动 Scene，再运行 `up -d --build`；重启会丢弃未保存会话。
