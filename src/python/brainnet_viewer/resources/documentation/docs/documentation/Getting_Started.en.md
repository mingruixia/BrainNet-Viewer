# Getting started with BrainNet Viewer 2.0

[中文](Getting_Started.zh-CN.md) · [Manual](../manual/en/index.md) · [Scene and preset details](Scene_Workflows.en.md)

For BrainNet Viewer `2.0.0`. Use the matching source or distribution and verify its release notes and checksums. MATLAB is required; this is not a MATLAB Runtime standalone. See the README for installation requirements and limitations.

## 1. Install and launch

Validation includes Windows MATLAB R2025a Update 1, focused Windows R2024b Update 1 checks and macOS R2024a team workflow checks. MATLAB must be installed and activated. MATLAB Runtime-only installation and Linux are not certified. Some features require additional toolboxes; see the [requirements and limitations](../../README.md#install-and-launch).

Set MATLAB's **Current Folder** to the project root containing the top-level `BrainNetViewer.m`, then run:

```matlab
app = BrainNetViewer;
```

That entry point adds `src/matlab/BrainNetViewer` itself. From another working folder, add the **project root** to the MATLAB path once before calling the same function. Avoid `addpath(genpath(...))`, the frozen legacy copy, or another BrainNet installation on the same path. No MATLAB Compiler installer is supplied.

## 2. Select and load data

In **Data Sources**, use **Add Files** or the individual Surface, Nodes, Edges, Volume, and related slots. **Open Scene JSON** is for an existing saved Scene, not a NIfTI or mesh. Select compatible files, then click **Validate and Load** to read them and see input errors before visualizing. A surface can be used alone; other roles depend on the intended visualization. The input roles and supported formats are summarized in the [README](../../README.md#workflow) and [surface-format matrix](../compatibility/Surface_Format_Support.md).

MATLAB opens selected local files directly at their original locations, without an import confirmation or automatic copies. Ordinary **Save Scene** JSON stores file references and hashes; it does not include the data. Keep those files at their recorded locations. For sharing or moving a project, select **Portable Scene with data (*.zip)** in the Save Scene dialog. The ZIP contains the inputs and supported paired or external data files. Open it with **Open Scene** on the destination computer. Older root-relative Scene JSON remains readable. A local JSON containing absolute references is intended for the same computer; use a ZIP when paths will change.

Check units, axes, species, and atlas/volume alignment before scientific interpretation. NIfTI header information does not automatically prove that a separately supplied surface is registered to that volume. A known format is not evidence of a valid coordinate match.

## 3. Configure, render, interact, export

Expand a **Visualization Settings** category on the right. The shared **Apply** commits pending changes **and renders** a loaded Scene; **Revert** discards pending changes without changing the applied settings. **Render Scene** explicitly redraws the current Scene, for example after camera or data changes. If the first Apply also needs to load inputs, it uses the same validation path. Avoid judging an old canvas after changing input files: the App clears the previous render.

Use the canvas tools to Rotate, Pan, Zoom, Fit or Reset the view. **Inspect** shows a label on the rendered canvas for a selected point; click Inspect again to clear it. AAL and Brodmann lookups use an assumed MNI-like coordinate interpretation, not a registration transform. Inspect results should not be reported as anatomical certainty until the input space is verified. **Export Figure** beneath Data Sources supports PNG, JPEG, TIFF, BMP, PDF and SVG with dimensions/resolution options; complex 3-D vector output may contain raster content. Exports create a provenance JSON sidecar that may include local paths—review it before sharing.

## 4. Save or reuse your work

Use **Save Scene** for an analysis you want to reopen: its JSON records input references and hashes, applied visualization settings, relevant coordinate/rights metadata, and (when valid) modern camera/export preferences. It does **not** embed the source data. Keep the same relative structure under the chosen data root when moving a Scene; after **Open Scene JSON**, use **Validate and Load** and render. An unapplied editor change is not saved as an applied Scene setting.

Use **Save Preset** for reusable appearance only. A preset does not carry input paths, camera state, or export-panel preferences. **Load Preset** reviews compatibility, then—on confirmation—replaces all display-setting sections, discards pending edits, and resets the camera; render again afterward. Recheck thresholds, colormap ranges, and ROI IDs for each new dataset. **Import Settings** accepts a *trusted* legacy EC `.mat` configuration through a separate conversion path; read the migration warnings before saving a modern Scene. See [Scene workflows](Scene_Workflows.en.md), [presets](Visualization_Presets.en.md), and [migration](Migration.en.md).

The current documentation and internal fixtures are not a cleared distribution package. In particular, an example used in tests may still require permission review before publication.
