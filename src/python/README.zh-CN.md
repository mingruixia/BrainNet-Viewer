# BrainNet Viewer Python 与 Web

BrainNet Viewer 2.0.0-beta.1 对应 Python 包版本2.0.0b1。
本源码使用2.0.0b1.post2，包含后续维护更新；已发行wheel及Docker Hub镜像未替换。
桌面版使用Qt和VTK；Web在Docker后台运行，通过浏览器1031端口访问。
两者均不需要MATLAB。

- [桌面版安装](../../docs/python/zh-CN/INSTALLATION.md)
- [Docker安装](../../docs/web/zh-CN/INSTALLATION.md)
- [统一教程（英文）](../../docs/tutorials/unified/en/index.md)
- [统一手册](../../docs/manual/en/index.md)
- [更新说明](CHANGELOG.md)

已安装桌面环境运行 python -m brainnet_viewer。开发时安装本目录并选择
desktop或web附加依赖。Dockerfile从本源码及随包资源构建Web镜像；
当前源码在所有平台上均要求Python 3.11或更新版本；pyproject.toml固定直接依赖。

选择输入文件、调整显示设置后，点击 **Apply** 绘图，随后可操作视图、导出图片或保存 Scene。安装包附带曲面模板、图谱示例、教程数据及 AAL/Brodmann Inspect 查询表。Web支持本机单一共享会话，源码启动时优先核验GPU，
不可用则切回CPU；容器能否分配GPU取决于Docker主机。
停止或更新容器前保存便携Scene。代码GPL-3.0-or-later，资源保留各自条款。

Web应在一名受信任用户的个人电脑上运行。浏览器来源检查不提供操作系统用户认证，
因此本地服务不适合多用户共享主机或公网部署。

开发者Mingrui Xia：mxia@bnu.edu.cn；mingruixia@gmail.com。
