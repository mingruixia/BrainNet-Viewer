# Unraid局域网镜像

`2.0.0-unraid.1`在已发行2.0.0基础上增加便捷局域网入口，不覆盖原`2.0.0`或`latest`镜像，绘制程序和资源保持2.0.0版本。

默认在Community Applications的Apps中安装后，直接打开WebUI，以`http://Unraid-IP:1031`使用；无需证书、密码文件或预先填写服务器地址。每个浏览器会话仍有独立进程与工作目录，同一浏览器配置的标签页共用会话。默认只自动接收私有/回环IP地址；使用域名时明确填写`BNV_SERVER_ORIGIN`。

HTTP通信不加密，能访问该端口的设备可以进入应用，默认模式适用于可信局域网。需要时在高级设置中分别启用HTTPS和访问密码，不要将默认免密码入口映射到公网。

| 设置 | 默认 | 可选配置 |
|---|---|---|
| BNV_SCHEME | http | https |
| BNV_PASSWORD_AUTH | off | on |
| BNV_SERVER_ORIGIN | 留空，自动识别实际私有IP和端口 | 明确的http(s)://主机:端口，不含路径 |
| 私有文件目录 | 默认不挂载 | 只读挂载到/run/bnv-secrets |

启用HTTPS时，准备`server.crt`与`server.key`，设置`BNV_SCHEME=https`并填写准确的HTTPS origin；证书须匹配该IP/域名，客户端信任签发者。相应修改WebUI快捷地址为HTTPS。仅启用密码时，准备一行16—256个UTF-8字节的随机密码文件`access_password.txt`，设置`BNV_PASSWORD_AUTH=on`。没有通用默认密码；需要加密时同时启用HTTPS。

上述私有文件及目录须可由UID10001读取，文件保持私有，以只读方式挂载；默认模式不要求创建这些文件或挂载目录。切换模式或更新容器前保存Scene，重启会结束未保存会话。Scene保存仍为可迁移ZIP，图片和JSON仍分别下载。

普通brainnet-server入口仍要求明确的安全配置；新增免密码/HTTP行为只有显式trusted-LAN模式或Unraid启动器启用。源码位于maintenance/unraid-easy-lan-20261102分支，构建使用src/python/Dockerfile.unraid和不可变2.0.0双架构基础索引。容器/API程序检查不代替原生Unraid安装、GPU透传或原生ARM64图形验收。
