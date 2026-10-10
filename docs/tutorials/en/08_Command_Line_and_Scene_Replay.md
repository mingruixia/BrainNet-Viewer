# 08 · Command-line rendering and Scene replay

[中文](../zh-CN/08_Command_Line_and_Scene_Replay.md) · [Tutorial index](index.md) · [Batch/provenance manual](../../manual/en/M14_Batch_Provenance.md) · [Real T-map lesson](05_Volume_to_Surface_Mapping.md)

This exercise renders the **same real, PCC-subregion one-sample connectivity T map** as Tutorials 05 and 07, now from a saved Scene JSON without opening the BrainNet Viewer desktop App. The NIfTI is not an Alzheimer's-versus-control contrast. The [resource note](Resource_Attribution.md) and the smoothed ICBM152 surface's Prof. Alan C. Evans (MNI) credit still apply. A MATLAB license and graphics-capable environment are required; Docker/Web has separate browser installation instructions.

The supplied [four-view Scene JSON](../assets/scenes/tutorial08-pcc-four-view.scene.json) is a portable *reference*, not an embedded data package. It was saved by the current App with `P = 0.001`, trilinear mapping, the signed color scale, four-view layout and source hashes. Its SHA-256 is `7d0c9b11c734f8297235d000927d2fab28301176106683d729e2e20bba439ab0`. It contains no machine-absolute path, but references the exact files `Data/SurfTemplate/BrainMesh_ICBM152_smoothed.nv` and `Data/Tutorials/OneSample_ROI11_NC.nii` relative to the **data root**. Keep those files alongside the source tree or supply a root with the same relative structure. The Scene is not a registration certificate or permission grant for new inputs.

## Steps

### Step 01 · Open MATLAB in the new project root

Set MATLAB's Current Folder to the **new** `BrainNetViewer_2026` project root, not the historical source folder. Run:

```matlab
projectRoot = string(pwd);
sourceRoot = fullfile(projectRoot,"src","matlab","BrainNetViewer");
addpath(sourceRoot);
scenePath = fullfile(projectRoot,"docs","tutorials","assets", ...
    "scenes","tutorial08-pcc-four-view.scene.json");
outputDir = fullfile(projectRoot,"tmp","tutorial08-cli");
if ~isfolder(outputDir), mkdir(outputDir); end
```

If MATLAB started elsewhere, set `projectRoot` explicitly to your **new project** root. `DataRoot` below is `sourceRoot`, not the Scene JSON's directory. Do not edit or copy from an original BrainNet folder for this exercise.

### Step 02 · Render PNG without opening the App

```matlab
pngPath = fullfile(outputDir,"pcc-four-view.png");
record = BrainNetRender(scenePath,pngPath, ...
    DataRoot=sourceRoot,ComputeBackend="cpu", ...
    PerformanceMode="quality",Width=960,Height=720, ...
    Resolution=150,Units="pixels",BackgroundColor="white");
info = imfinfo(pngPath);
[info.Width info.Height]  % [960 720]
```

The current-build focused R2025a check produced this image with four surface views and a signed colorbar, plus `pcc-four-view.png.provenance.json`. The CLI uses a hidden modern figure; it does not start the App. It checks referenced input hashes before rendering. The figure is visually comparable to the App example, but pixel-identical output across graphics drivers or versions is not promised.

![Figure-only CLI render of the real one-sample T map in four views](../assets/captures/tutorial08-cli/08-pcc-four-view-cli.png)

*Current-build 960 × 720 PNG from the supplied Scene on R2025a Update 1. It shows a one-sample connectivity T map, not a group difference; the uncorrected voxelwise threshold and interpolation limits remain as in Tutorial 05.*

### Step 03 · Reuse the Scene for a second output

Use a **different** output name for a 1200 × 900 TIFF. The focused check confirmed its format, dimensions and neighboring provenance sidecar.

```matlab
tifPath = fullfile(outputDir,"pcc-four-view-1200x900.tif");
BrainNetRender(scenePath,tifPath, ...
    DataRoot=sourceRoot,ComputeBackend="cpu", ...
    PerformanceMode="quality",Width=1200,Height=900, ...
    Resolution=300,Units="pixels",BackgroundColor="white");
imfinfo(tifPath)  % check Width, Height and Format
```

These two calls illustrate a small batch with one frozen scientific Scene and two *output* specifications. The `300` DPI request is not independent validation of physical print size in every downstream tool. For several different analyses, save and verify a separate Scene for each input set rather than editing the JSON paths by hand.

### Step 04 · Inspect provenance and replay rules

```matlab
sidecar = jsondecode(fileread(pngPath + ".provenance.json"));
sidecar.kind
sidecar.scene.inputs.volume.sha256
sidecar.export.actual_width_pixels
```

 **Do not share the raw sidecar without checking paths and metadata.** The tool will not overwrite an existing image or sidecar unless `Overwrite=true`; use new names in ordinary work. An incorrect `DataRoot` makes input resolution fail rather than silently substituting another volume. Saved camera state is used only when its Scene-content signature is compatible; a different window or graphics backend may still change framing, so inspect each output. The Scene stores references and applied settings, not NIfTI/mesh bytes, unapplied edits, or proof of registration.

## Troubleshooting

- **Input not found / hash mismatch:** point `DataRoot` at the `BrainNetViewer` source folder with the exact two files and directory structure. Do not point it at the JSON file's folder or replace a changed file silently.
- **Output exists:** choose another file name, or explicitly approve an overwrite after inspecting both image and sidecar. The tutorial check deliberately verified default overwrite protection.
- **Render/graphics error:** a desktop App window is unnecessary, but MATLAB still needs a working graphics environment. Check graphics support before using a headless server.
