# M01 · Installation, launch and version scope

[中文](../zh-CN/M01_Installation_Launch.md) · [Manual index](index.md) · [First-launch tutorial](../../tutorials/en/00_First_Launch.md) · [Requirements](../../../README.md#requirements-and-scope)

BrainNet Viewer is a MATLAB desktop application for visualizing brain surfaces, networks and mapped volumes. This chapter explains installation requirements, startup and the main workflow.

## Supported starting point

The primary tested desktop environment is **Windows with an installed, activated MATLAB R2025a Update 1** and a graphics-capable session. Focused app, layout, dialog and raster-export checks have also passed on macOS R2024a/R2026a, but a complete macOS package is not certified. MATLAB Runtime-only installation, Linux packaging and a standalone executable are not certified. The independent modern NIfTI/GIfTI readers do not require SPM, but individual optional features can need MATLAB toolboxes or GPU support. See the [project README](../../../README.md) and the [migration limits](../../documentation/Migration.en.md); a successful launch does not verify every optional feature.

Set MATLAB **Current Folder** to the installed software root, the directory containing the top-level `BrainNetViewer.m`, then run:

```matlab
app = BrainNetViewer;
```

The launcher adds `src/matlab/BrainNetViewer` itself. From elsewhere, add **only the installed software root** to MATLAB's path first. Do not use `addpath(genpath(...))`, mix different software versions, or assume that a different installed `BrainNetViewer` is the intended installation. In MATLAB, `which BrainNetViewer -all` helps diagnose a path collision. No installer is supplied by this chapter.

## What should appear

The English main window opens with its startup image/build information. Its three working areas support the intended sequence: **Data Sources → Visualization Settings → render in the main canvas → interact/export**. Use **Add Files** or role-specific slots, **Validate and Load**, change settings, then the shared **Apply**; Apply commits and renders. **Render Scene** is an explicit redraw.

Start with the authorized real [ICBM152 surface exercise](../../tutorials/en/00_First_Launch.md), not an arbitrary template found in a data directory. For file roles, coordinate cautions and data-root behavior, continue to [M02](M02_Data_Formats_Coordinates.md). For saving an analysis, use [M03](M03_Scenes_Presets_Legacy.md).

## Before sharing an image or package

The UI version/build date identifies this development build, not a public release date. A figure's provenance may contain local file paths. **Directory membership is not redistribution permission**; check source credits and package notices before sharing teaching data. The internal Beta 1 ZIP and the current workspace may differ. Review the [changelog](../../../CHANGELOG.md) and the actual package contents before asserting version or compatibility claims.
