# Python desktop installation

BrainNet Viewer 2.0.0-beta.1 uses Python package version **2.0.0b1**.
Obtain brainnet_viewer-2.0.0b1-py3-none-any.whl from the accompanying GitHub or
NITRC release and verify its SHA-256 against that release's SHA256SUMS.
MATLAB and SPM are not required. Dependencies need Internet access unless
supplied in a separate offline collection.

Apple Silicon macOS requires Python 3.11 or newer; Python 3.11 is the verified
configuration. Windows, Linux and Intel macOS use Python 3.10 or 3.11. A graphical
desktop with working OpenGL and a writable folder is required.
Windows x64 and Apple Silicon macOS have focused development checks;
Linux Desktop and Intel Mac require their own validation. Preserve dependency
pins and create a separate virtual environment.

## Windows

Open PowerShell in the wheel directory:

```powershell
py -3.10 -m venv .venv-bnv
$bnvPython = (Resolve-Path .venv-bnv/Scripts/python.exe).Path
$bnvWheel = (Resolve-Path brainnet_viewer-2.0.0b1-py3-none-any.whl).Path
$bnvWheelUrl = & $bnvPython -c "from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve().as_uri())" $bnvWheel
& $bnvPython -m pip install "brainnet-viewer[desktop] @ $bnvWheelUrl"
& $bnvPython -m pip check
& $bnvPython -m brainnet_viewer
```

If py is unavailable, use the full Python 3.10 path for the first command.
After installation, .venv-bnv/Scripts/brainnet-viewer.exe starts the graphical
app without a new console. The module command above shows startup errors.

## macOS and Linux

On the graphical desktop, open a terminal in the wheel directory:

```bash
python3.11 -m venv .venv-bnv
source .venv-bnv/bin/activate
BNV_WHEEL="$(pwd)/brainnet_viewer-2.0.0b1-py3-none-any.whl"
BNV_WHEEL_URL="$(python -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve().as_uri())' "$BNV_WHEEL")"
python -m pip install "brainnet-viewer[desktop] @ $BNV_WHEEL_URL"
python -m pip check
brainnet-viewer
```

On Apple Silicon macOS, use the Python 3.11 command above. The package selects
SciPy 1.17.1 for native ARM64 macOS; this dependency requires Python 3.11 or newer.
On Linux or Intel macOS, Python 3.10 may be used instead for the first command;
these platforms retain SciPy 1.15.3. Never copy virtual environments between
operating systems.

## First use

Load inputs, configure Visualization Settings, then Apply. Rotate, Pan and Zoom
operate on the selected view. Export Figure saves images and provenance.
Save Scene preserves inputs and settings; a preset contains settings only.
Use the [shared tutorials](../../tutorials/unified/en/index.md) and
[manual](../../manual/en/index.md).

The wheel includes the original surfaces, atlas-network examples, real tutorial
inputs and dual-atlas Inspect tables. Find resources with the installed Python:

```text
python -c "from importlib.metadata import version; print(version('brainnet-viewer'))"
python -c "from pathlib import Path; import brainnet_viewer; print(Path(brainnet_viewer.__file__).parent / 'resources')"
```

On Windows replace python with & $bnvPython. Copy examples before editing them.
For CLI export, use a same-edition Scene and the shared command-line tutorial.

## Troubleshooting

- Missing dependency: retain Python version, architecture, index and full pip
  error. Keep pins and global settings unchanged.
- Missing dependencies for SOCKS support: pip may have inherited a SOCKS proxy.
  Confirm whether it is needed; temporarily clear unwanted proxy variables
  only in this terminal, or configure a working HTTP proxy.
- Startup error: use this environment's module command, run pip check and confirm
  the desktop extra was installed.
- Blank rendering: check drivers and the graphical session; include GPU/display
  scaling details with a reproducible report.

For browser use see [Docker installation](../../web/en/INSTALLATION.md).
Contact Mingrui Xia: mxia@bnu.edu.cn; mingruixia@gmail.com.

## Install the current source

The default source branch includes maintenance updates (package version
2.0.0b1.post2) that are not in the downloadable 2.0.0b1 wheel. For source
installation, open a terminal at the complete repository root and use a new
environment. Python 3.12 is recommended on Windows; Apple Silicon still requires
Python 3.11 or newer. Do not reuse or change an existing beta environment.

Windows PowerShell:

```powershell
py -3.12 -m venv .venv-bnv-source
$bnvPython = (Resolve-Path .venv-bnv-source/Scripts/python.exe).Path
& $bnvPython -m pip install "./src/python[desktop]"
& $bnvPython -m pip check
& $bnvPython -m brainnet_viewer
```

macOS/Linux Terminal:

```bash
python3.11 -m venv .venv-bnv-source
source .venv-bnv-source/bin/activate
python -m pip install './src/python[desktop]'
python -m pip check
brainnet-viewer
```

Keep the project's dependency pins. Source installation does not update any
previously installed wheel or downloaded package. Platform/graphics requirements
still apply; a successful installation alone does not verify rendering.
