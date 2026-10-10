BrainNet Viewer 2.0 — Installation
Developer: Mingrui Xia
Contact: mxia@bnu.edu.cn; mingruixia@gmail.com

MATLAB INSTALLATION
Extract the MATLAB archive into a new local writable folder. Do not overwrite
an old installation. In MATLAB, change Current Folder to the extracted folder
containing BrainNetViewer.m, then run:
    app = BrainNetViewer;
Avoid adding an old BrainNet Viewer installation to the MATLAB path at the
same time. MATLAB is required; this is not a standalone application.

PYTHON REQUIREMENTS
Python Desktop uses Python, Qt and VTK; MATLAB and SPM are not required.
Use Python 3.10 or 3.11, a local graphical desktop with working OpenGL, and a
writable user folder. Dependency installation needs network access unless the
fixed dependencies are supplied separately. Do not copy environments between
machines or silently change the wheel's fixed dependency constraints.
The wheel contains the original surface library, atlas/network examples,
real tutorial data, dual-atlas Inspect tables and resource notices.

PYTHON INSTALLATION — WINDOWS
Extract the Python archive and open PowerShell in that folder. These commands
create an independent environment without changing system Python:
    py -3.10 -m venv .venv-bnv
    $bnvPython = (Resolve-Path .venv-bnv/Scripts/python.exe).Path
    $bnvWheel = (Resolve-Path brainnet_viewer-2.0.0b1-py3-none-any.whl).Path
    $bnvWheelUrl = & $bnvPython -c "from pathlib import Path; import sys; print(Path(sys.argv[1]).as_uri())" $bnvWheel
    & $bnvPython -m pip install "brainnet-viewer[desktop] @ $bnvWheelUrl"
    & $bnvPython -m pip check
    & $bnvPython -m brainnet_viewer
Use the supplied wheel's actual filename if it changes. If py is unavailable,
replace py -3.10 with the full path to your Python 3.10 executable.
After installation, double-click .venv-bnv/Scripts/brainnet-viewer.exe
to launch without retaining a command window. For error output, launch with
the environment's python -m brainnet_viewer instead.

PYTHON INSTALLATION — macOS
Use Python 3.10 or 3.11. In a terminal in the extracted Python folder:
    python3 -m venv .venv-bnv
    source .venv-bnv/bin/activate
    BNV_WHEEL_URL="$(python -c 'from pathlib import Path; print(Path("brainnet_viewer-2.0.0b1-py3-none-any.whl").resolve().as_uri())')"
    python -m pip install "brainnet-viewer[desktop] @ $BNV_WHEEL_URL"
    python -m pip check
    brainnet-viewer
Use the supplied wheel's actual filename if it changes. Do not copy a Windows
virtual environment onto a Mac. This is a desktop package, not a standalone
executable, offline installer, Docker image or browser application.

LOCATE PYTHON RESOURCES
Run with the installed environment's Python. In Windows PowerShell, substitute
& $bnvPython for python in the following command:
    python -c "from pathlib import Path; import brainnet_viewer; print(Path(brainnet_viewer.__file__).parent / 'resources')"
The resource folder contains Data/SurfTemplate, Data/ExampleFiles and
Data/Tutorials. File pickers default to the relevant bundled library. Copy
examples into your own writable folder before editing them.

GUIDES
All three editions provide the unified English Word/PDF manual and shared
illustrated tutorials. Open Help in the application. The MATLAB unified PDF
is under docs/manual/en; the Python manual is in the installed resource folder
under documentation/docs/manual/en. Retain GPL and resource/third-party notices.

INSTALLATION TROUBLESHOOTING — SOCKS PROXY
"Missing dependencies for SOCKS support" indicates that pip is trying to use
a SOCKS proxy without its optional SOCKS support. It is not a wheel-corruption
message. If your local proxy also provides HTTP on port 10808, keep it running
and retry the failed install in the same PowerShell window with:
    & $bnvPython -m pip install --proxy "http://127.0.0.1:10808" "brainnet-viewer[desktop] @ $bnvWheelUrl"
    & $bnvPython -m pip check
This overrides the proxy for that command only; it does not change Windows
proxy settings or fixed dependencies. Substitute your actual HTTP proxy port
if different. Do not label a SOCKS-only port as HTTP. If this reports a refused
connection or timeout, check the proxy service and HTTP listener first.

DOCKER / WEB INSTALLATION
Install and start Docker with Linux containers. Extract the Web package and
open a terminal in the folder containing compose.web.release.yml, then run:
    docker compose -f compose.web.release.yml pull
    docker compose -f compose.web.release.yml up -d
Open http://127.0.0.1:1031/index.html. MATLAB and local Python are not needed.
Read docs/web/en/INSTALLATION.md for platform setup and troubleshooting.
Save Scene before stopping Docker; uploads and unsaved sessions are temporary.
