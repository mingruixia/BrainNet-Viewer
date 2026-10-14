# Installation, launch and version scope

[中文](../zh-CN/M01_Installation_Launch.md) · [Manual index](index.md) · [First-launch tutorial](../../tutorials/en/00_First_Launch.md) · [Requirements](../../../README.md#install-and-launch)

BrainNet Viewer is a MATLAB desktop application for visualizing brain surfaces, networks and mapped volumes. This chapter explains installation requirements, startup and the main workflow.

## Supported starting point

Use an installed, activated MATLAB with a working graphics session. Windows with **MATLAB R2025a Update 1** is the primary tested configuration. Selected app, layout, dialog and raster-export workflows have also been tested on macOS R2024a/R2026a; these checks do not cover every feature. A MATLAB Runtime-only package, Linux package and standalone executable are not supplied. The independent modern NIfTI/GIfTI readers do not require SPM, but individual optional features can need MATLAB toolboxes or GPU support. See the [project README](../../../README.md) and the [migration limits](../../documentation/Migration.en.md); optional features have their own requirements.

Set MATLAB **Current Folder** to the installed software root, the directory containing the top-level `BrainNetViewer.m`, then run:

```matlab
app = BrainNetViewer;
```

The launcher adds `src/matlab/BrainNetViewer` itself. From elsewhere, add **only the installed software root** to MATLAB's path first. Do not use `addpath(genpath(...))`, mix different software versions, or assume that a different installed `BrainNetViewer` is the intended installation. In MATLAB, `which BrainNetViewer -all` helps diagnose a path collision. Start the application directly from its software directory.

## What should appear

The English main window contains Data Sources, the render canvas and Visualization Settings. Select files with **Add Files** or the individual input controls, then click **Validate and Load**. Adjust the settings and click **Apply** to commit them and render the Scene. Use **Render Scene** when you need to redraw it.

For a first visualization, follow the [ICBM152 surface exercise](../../tutorials/en/00_First_Launch.md). For file roles, coordinate cautions and data-root behavior, continue to [M02](M02_Data_Formats_Coordinates.md). For saving an analysis, use [M03](M03_Scenes_Presets_Legacy.md).

## Before sharing an image or package

Review a figure's provenance for private file paths before sharing it. Check the source credits and resource notices before redistributing teaching data; inclusion in the software directory does not itself grant permission. The [changelog](../../../CHANGELOG.md) describes version changes.
