# Custom colormaps and visualization presets

[中文](../zh-CN/M11_Colormaps_Presets.md) · [Manual index](index.md) · [Illustrated real-data exercise](../../tutorials/en/09_Presets_and_Custom_Colormaps.md) · [Colormap details](../../documentation/Colormaps.en.md) · [Preset details](../../documentation/Visualization_Presets.en.md)

Use custom colormaps to control display colors and visualization presets to reuse settings across datasets. A colormap changes appearance, not numerical values, thresholds or registration. A preset transfers display settings, not data files.

## Custom RGB colormaps

Open **Colors...** below **Load Preset / Save Preset** in the right-hand Visualization Settings panel. The editor has four independent **Target** choices: **Surface**, **Nodes**, **Edges** and **Volume**. Volume uses one signed colormap, not separate positive and negative palettes. Named choices now include Viridis, Plasma, Inferno, Magma and Cividis; these are also available directly from each target's colormap selector. Choose a named **Preset** and **Count** (2–4096 rows), then **Generate**; **Resample** interpolates the current table to Count, and **Reverse** reverses its row order. The Red/Green/Blue table accepts finite components in [0,1]; a valid edit updates the preview. **Import...** reads RGB TXT/JSON; **Export...** writes the current target's table only, without applying it. Existing export files require an overwrite decision.

**Use in Settings** stages the four maps in the right-hand panel and closes the editor. **Cancel**/closing discards editor changes. A merely viewed named map stays named; modifying it produces an embedded numeric map. Choose a display mode that consumes that target's colormap, then press the single panel-bottom **Apply**: it commits settings **and renders**. **Revert** discards pending panel edits. A separate Render Scene click is unnecessary after a successful Apply.

Surface Scalar, Node Mapped/Modules, Edge Mapped, and Volume Surface Map are examples of applicable consumers. In **Edge Node Module** mode, same-module edges inherit the **Node** module palette, not the Edge colormap. Node and Edge fixed threshold colors do not use the continuous palette. For **Volume Display Values = Positive & Negative**, the one map is split at its midpoint between negative and positive values; review the resulting signed colorbar and limits. The ROI **Label Index** palette is a separate categorical selector in Volume settings, not an editor target. Numeric palettes are RGB-interpolated, not guaranteed perceptually uniform or accessible. See the [node](M07_Nodes.md), [edge](M08_Edges.md), [volume](M09_Volume_Mapping.md) and [ROI](M10_ROI_Inspection.md) chapters before interpreting colors scientifically.

RGB TXT accepts three numeric channels per row; expressions are not executed. JSON uses `kind: brainnet-colormap`, schema `1.0`, and a `colors` array. File import is limited to 1 MiB. Scene and preset JSON retain applied custom arrays; the editor's Export... creates only a portable colormap file. The legacy renderer does not silently substitute unsupported custom arrays. Treat imported legacy MAT configuration files as trusted-code inputs and review old combined volume palettes manually.

## Save and load a display preset

1. Load a dataset and edit Visualization Settings. Press **Apply** to commit and render.
2. Press **Save Preset** to write `*.preset.json`. This captures **applied** settings, not uncommitted edits, input paths, camera, theme, compute backend or export-panel preferences.
3. With another dataset, press **Load Preset**. Read the compatibility review and confirm or cancel. Confirmation replaces all nine display sections and pending edits, retains the current input references and export preferences, and clears the old render/camera. Press **Render Scene** after loading.
4. Recheck data-specific color limits, thresholds, units, selected ROI IDs and anatomy before exporting. A role-compatibility warning is not proof of spatial registration or scientific validity.

**Save Scene** is different: it records one Scene's input references, settings and (when saved from the modern App) session camera/export preferences; input files are referenced, not bundled. Invalid, unknown-version or explicitly input/camera-bearing preset JSON is rejected. Cancellation and failed validation do not replace the current settings. Fiber rendering remains unavailable; Surface Map and statistical ROI P-value presets require supported statistic metadata in the selected NIfTI. Preset names/titles may contain private text; review before sharing.

The [real-data illustrated exercise](../../tutorials/en/09_Presets_and_Custom_Colormaps.md) shows custom Volume RGB staging, Apply and preset replay. Check the resulting colorbar and limits against the loaded data before reusing a preset in a figure.
