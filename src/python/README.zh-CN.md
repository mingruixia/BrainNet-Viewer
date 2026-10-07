# BrainNet Viewer Python 与 Web

BrainNet Viewer 2.0.0-beta.1 对应 Python 包版本2.0.0b1。
桌面版使用Qt和VTK；Web在Docker后台运行，通过浏览器1031端口访问。
两者均不需要MATLAB。

- [桌面版安装](../../docs/python/zh-CN/INSTALLATION.md)
- [Docker安装](../../docs/web/zh-CN/INSTALLATION.md)
- [统一教程（英文）](../../docs/tutorials/unified/en/index.md)
- [统一手册](../../docs/manual/en/index.md)
- [更新说明](CHANGELOG.md)

已安装桌面环境运行 python -m brainnet_viewer。开发时安装本目录并选择
desktop或web附加依赖。Dockerfile从本源码及随包资源构建Web镜像；
pyproject.toml固定直接依赖。

读取文件、配置、Apply绘图、交互、导出。随包提供原曲面库、图谱示例、
教程数据和双图谱Inspect表。Web支持本机单一共享会话和软件渲染，
停止或更新容器前保存便携Scene。代码GPL-3.0，资源保留各自条款。

开发者Mingrui Xia：mxia@bnu.edu.cn；mingruixia@gmail.com。
