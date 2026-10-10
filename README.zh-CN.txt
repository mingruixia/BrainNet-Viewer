BrainNet Viewer 2.0 — 桌面版安装说明
开发者：Mingrui Xia
联系邮箱：mxia@bnu.edu.cn；mingruixia@gmail.com

MATLAB 安装
将 MATLAB 压缩包解压到新的本机可写目录，不覆盖旧安装。在 MATLAB 中，
将 Current Folder 切换到含 BrainNetViewer.m 的解压根目录，然后运行：
    app = BrainNetViewer;
不要同时把旧 BrainNet Viewer 安装加入 MATLAB 搜索路径。本版需要 MATLAB，
不是独立可执行程序。

PYTHON 环境要求
Python 桌面版使用 Python、Qt 和 VTK，不需要 MATLAB 或 SPM。
Apple Silicon macOS 要求 Python 3.11 或更新版本，已验证 Python 3.11。
Windows、Linux 和 Intel macOS 使用 Python 3.10 或 3.11。
需要具有可用 OpenGL 的本地图形桌面和可写用户目录。
除非已另行提供固定版本依赖，安装依赖需要联网。不要在机器之间复制虚拟
环境，不要静默放宽 wheel 中固定的依赖约束。
wheel 包含原有曲面库、图谱/网络示例、真实教程数据、双图谱 Inspect 表及
资源说明。

PYTHON 安装 — WINDOWS
解压 Python 压缩包，在解压目录打开 PowerShell。以下命令创建独立环境，
不改变系统 Python：
    py -3.10 -m venv .venv-bnv
    $bnvPython = (Resolve-Path .venv-bnv/Scripts/python.exe).Path
    $bnvWheel = (Resolve-Path brainnet_viewer-2.0.0b1-py3-none-any.whl).Path
    $bnvWheelUrl = & $bnvPython -c "from pathlib import Path; import sys; print(Path(sys.argv[1]).as_uri())" $bnvWheel
    & $bnvPython -m pip install "brainnet-viewer[desktop] @ $bnvWheelUrl"
    & $bnvPython -m pip check
    & $bnvPython -m brainnet_viewer
若随包 wheel 名称变化，请替换成实际文件名。若系统没有 py 启动器，将
py -3.10 替换为本机 Python 3.10 可执行文件的完整路径。
安装完成后，双击 .venv-bnv/Scripts/brainnet-viewer.exe 即可启动，
无需保留命令窗口。需要查看报错时，用该环境的 python -m brainnet_viewer 启动。

PYTHON 安装 — macOS
Apple Silicon 请使用 Python 3.11，在 Python 解压目录的终端中运行：
    python3.11 -m venv .venv-bnv
    source .venv-bnv/bin/activate
    BNV_WHEEL_URL="$(python -c 'from pathlib import Path; print(Path("brainnet_viewer-2.0.0b1-py3-none-any.whl").resolve().as_uri())')"
    python -m pip install "brainnet-viewer[desktop] @ $BNV_WHEEL_URL"
    python -m pip check
    brainnet-viewer
原生 ARM64 macOS 自动选择 SciPy 1.17.1，要求 Python 3.11 或更新版本。
Intel macOS 第一条命令也可用 Python 3.10，并保留 SciPy 1.15.3。
若随包 wheel 名称变化，请替换成实际文件名。不要把 Windows 虚拟环境复制
到 Mac。本包是桌面软件，不是独立程序、离线安装器、Docker 镜像或浏览器应用。

定位 PYTHON 资源
使用已安装环境的 Python 运行以下命令。在 Windows PowerShell 中，将
python 替换为 & $bnvPython：
    python -c "from pathlib import Path; import brainnet_viewer; print(Path(brainnet_viewer.__file__).parent / 'resources')"
输出的资源目录含 Data/SurfTemplate、Data/ExampleFiles 和 Data/Tutorials。
文件选择器默认打开对应资源库。修改示例前，请先复制到自己的可写目录。

指南
三版均提供统一英文 Word/PDF 手册和共享图文教程，可从软件 Help 打开。
MATLAB 统一 PDF 位于 docs/manual/en；Python 手册位于已安装资源目录下的
documentation/docs/manual/en。保留随附 GPL、资源署名和第三方许可说明。

安装排错 — SOCKS 代理
“Missing dependencies for SOCKS support”表示 pip 正在尝试使用 SOCKS 代理，
但缺少可选的 SOCKS 支持；不是 wheel 文件损坏提示。若本机代理同时在
10808 端口提供 HTTP 服务，请保持代理程序运行，在原 PowerShell 窗口重试：
    & $bnvPython -m pip install --proxy "http://127.0.0.1:10808" "brainnet-viewer[desktop] @ $bnvWheelUrl"
    & $bnvPython -m pip check
该参数只覆盖本条命令的代理，不修改 Windows 代理设置或固定依赖。
若实际 HTTP 代理端口不同，请替换成实际端口；不要把纯 SOCKS 端口当作 HTTP。
若随后提示连接被拒绝或超时，请先检查代理程序及 HTTP 监听端口。

DOCKER / WEB安装
安装并启动Docker，使用Linux容器。解压Web软件包，在包含compose.web.release.yml的目录打开终端，执行：
    docker compose -f compose.web.release.yml pull
    docker compose -f compose.web.release.yml up -d
浏览器打开http://127.0.0.1:1031/index.html，无需MATLAB或本机Python。
平台设置及故障排查见docs/web/zh-CN/INSTALLATION.md。停止Docker前保存Scene，上传数据和未保存场景仅暂存于容器。
