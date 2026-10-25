# Python 桌面版安装

BrainNet Viewer 2.0.0-beta.1 对应 Python 包版本 **2.0.0b1**。
从配套 GitHub 或 NITRC 发行页面获取 brainnet_viewer-2.0.0b1-py3-none-any.whl，
根据该版 SHA256SUMS 校验。不需要 MATLAB 或 SPM。
除非另备离线依赖集合，安装依赖需要联网。
当前源码在所有平台上均要求Python 3.11或更新版本。

Apple Silicon macOS 要求 Python 3.11 或更新版本，已验证配置为 Python 3.11。
新安装应选择仍受维护的版本：
公测版建议使用 Python 3.11，当前 Windows 源码建议使用 Python 3.12。
Python 3.10 已于 2026 年 10 月 1 日停止支持，见 [Python 发行计划](https://peps.python.org/pep-0619/)。
需要支持 OpenGL 的图形桌面和可写目录。
部分桌面工作流程已在 Windows x64 和 Apple Silicon macOS 上测试，Linux Desktop 和 Intel Mac 尚未验证。请在独立虚拟环境中安装项目指定的依赖版本。

## Windows

在 wheel 目录打开 PowerShell：

```powershell
py -3.11 -m venv .venv-bnv
$bnvPython = (Resolve-Path .venv-bnv/Scripts/python.exe).Path
$bnvWheel = (Resolve-Path brainnet_viewer-2.0.0b1-py3-none-any.whl).Path
$bnvWheelUrl = & $bnvPython -c "from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve().as_uri())" $bnvWheel
& $bnvPython -m pip install "brainnet-viewer[desktop] @ $bnvWheelUrl"
& $bnvPython -m pip check
& $bnvPython -m brainnet_viewer
```

如无 py 启动器，第一行使用 Python 3.11 完整路径。
安装后可运行 .venv-bnv/Scripts/brainnet-viewer.exe，不会新建控制台；
排查错误时使用上面的模块启动命令。

## macOS 和 Linux

在图形桌面终端进入 wheel 目录：

```bash
python3.11 -m venv .venv-bnv
source .venv-bnv/bin/activate
BNV_WHEEL="$(pwd)/brainnet_viewer-2.0.0b1-py3-none-any.whl"
BNV_WHEEL_URL="$(python -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve().as_uri())' "$BNV_WHEEL")"
python -m pip install "brainnet-viewer[desktop] @ $BNV_WHEEL_URL"
python -m pip check
brainnet-viewer
```

Apple Silicon macOS 请使用上面的 Python 3.11 命令。原生 ARM64 macOS 自动选择
SciPy 1.17.1，该依赖要求 Python 3.11 或更新版本。Linux 和 Intel macOS
保留 SciPy 1.15.3。不要跨系统复制虚拟环境。

## 首次使用

当前源码包含用于中文和支持的Unicode图件文字的随附字体，不支持的字形会明确报错，不再静默丢失。混合Unicode节点标签使用随附回退字体，纯ASCII标签保留所选字体。长标题在标题区内适配；无法清晰容纳时，请加宽画布或缩短标题。PDF中的回退字体文字保存为字形轮廓。

选择输入文件，在 **Visualization Settings** 中调整设置，点击 **Apply** 绘图。**Rotate**、**Pan** 和 **Zoom** 操作所选视图。**Export Figure** 保存图片和溯源记录；**Save Scene** 保存输入与设置，便于再次打开。Preset 只保存显示设置。使用[统一教程（英文）](../../tutorials/unified/en/index.md)
和[手册](../../manual/en/index.md)。

wheel 包含曲面模板、图谱网络示例、教程数据及 AAL/Brodmann Inspect 查询表。
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

## 安装当前源码

默认源码分支包含后续维护更新（包版本2.0.0b1.post2），不在已下载的2.0.0b1
wheel中。请在完整仓库根目录打开终端，用Python 3.11或更新版本创建新环境；
Windows推荐Python 3.12。当前源码已停止支持Python 3.10，因为修复安全漏洞的
Pillow版本要求Python 3.11。请新建环境，不要直接升级已有公测环境。

Windows PowerShell：

```powershell
py -3.12 -m venv .venv-bnv-source
$bnvPython = (Resolve-Path .venv-bnv-source/Scripts/python.exe).Path
& $bnvPython -m pip install "./src/python[desktop]"
& $bnvPython -m pip check
& $bnvPython -m brainnet_viewer
```

macOS/Linux终端：

```bash
python3.11 -m venv .venv-bnv-source
source .venv-bnv-source/bin/activate
python -m pip install './src/python[desktop]'
python -m pip check
brainnet-viewer
```

请保留项目指定的依赖版本。源码安装不会修改已有 wheel 环境或下载包。安装后应启动软件并绘制一个示例，检查图形环境是否可用。
