# Python 桌面版安装

BrainNet Viewer 2.0.0-beta.1 对应 Python 包版本 **2.0.0b1**。
从配套 GitHub 或 NITRC 发行页面获取 brainnet_viewer-2.0.0b1-py3-none-any.whl，
根据该版 SHA256SUMS 校验。不需要 MATLAB 或 SPM。
除非另备离线依赖集合，安装依赖需要联网。

使用 Python 3.10 或 3.11、支持 OpenGL 的图形桌面和可写目录。
Windows x64 和 Apple Silicon macOS 有开发专项检查；Linux Desktop 和
Intel Mac 需独立验证。保留固定依赖，每次使用独立虚拟环境。

## Windows

在 wheel 目录打开 PowerShell：

```powershell
py -3.10 -m venv .venv-bnv
$bnvPython = (Resolve-Path .venv-bnv/Scripts/python.exe).Path
$bnvWheel = (Resolve-Path brainnet_viewer-2.0.0b1-py3-none-any.whl).Path
$bnvWheelUrl = & $bnvPython -c "from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve().as_uri())" $bnvWheel
& $bnvPython -m pip install "brainnet-viewer[desktop] @ $bnvWheelUrl"
& $bnvPython -m pip check
& $bnvPython -m brainnet_viewer
```

如无 py 启动器，第一行使用 Python 3.10 完整路径。
安装后可运行 .venv-bnv/Scripts/brainnet-viewer.exe，不会新建控制台；
排查错误时使用上面的模块启动命令。

## macOS 和 Linux

在图形桌面终端进入 wheel 目录：

```bash
python3 -m venv .venv-bnv
source .venv-bnv/bin/activate
BNV_WHEEL="$(pwd)/brainnet_viewer-2.0.0b1-py3-none-any.whl"
BNV_WHEEL_URL="$(python -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve().as_uri())' "$BNV_WHEEL")"
python -m pip install "brainnet-viewer[desktop] @ $BNV_WHEEL_URL"
python -m pip check
brainnet-viewer
```

第一行请选择 Python 3.10 或 3.11；不要跨系统复制虚拟环境。

## 首次使用

读取文件、配置 Visualization Settings 并 Apply 绘图。Rotate、Pan、Zoom
操作所选子图。Export Figure 保存图片及溯源记录；Save Scene 保存输入和设置，
Preset 只保存配置。使用[统一教程（英文）](../../tutorials/unified/en/index.md)
和[手册](../../manual/en/index.md)。

wheel 包含原曲面库、图谱网络示例、真实教程数据和双图谱 Inspect 表。
使用已安装环境的 Python 查询版本和资源：

```text
python -c "from importlib.metadata import version; print(version('brainnet-viewer'))"
python -c "from pathlib import Path; import brainnet_viewer; print(Path(brainnet_viewer.__file__).parent / 'resources')"
```

Windows 将 python 换成 & $bnvPython；修改示例前先复制。
CLI 导出使用本版本 Scene，参见统一命令行教程。

## 故障排查

- 依赖缺失：保留 Python 版本、架构、软件源及完整 pip 错误，保留固定依赖和全局设置。
- Missing dependencies for SOCKS support：pip 可能继承 SOCKS 代理。
  确认是否需要后，仅在当前终端临时清除不需要的代理变量，或配置可用 HTTP 代理。
- 启动失败：使用本环境模块命令，运行 pip check，确认安装 desktop 附加依赖。
- 画布空白：检查驱动及图形桌面，在可复现报告中附 GPU 和显示缩放信息。

浏览器使用参见[Docker安装](../../web/zh-CN/INSTALLATION.md)。
联系人 Mingrui Xia：mxia@bnu.edu.cn；mingruixia@gmail.com。
