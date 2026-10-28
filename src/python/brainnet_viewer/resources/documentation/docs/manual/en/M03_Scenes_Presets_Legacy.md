# Scenes, presets and legacy configurations

[Manual](index.md) · [中文](../zh-CN/M03_Scenes_Presets_Legacy.md) · [Previous: data and coordinates](M02_Data_Formats_Coordinates.md)

## Choose the right file

The numbered interface illustrations identify the main sequence: **1 Surface Mesh Add → 2 Validate and Load → 3 Surface settings → 4 Apply → 5 Save Scene**. For an existing Scene, use **Scene File → Open** instead of loading its inputs individually.

| Need | Use | What it contains |
|---|---|---|
| Reopen a complete visualization | Scene JSON | Input references and hashes, applied visualization settings, and supported camera/export session state; not the data bytes |
| Reuse a look on different data | Visualization Preset | Display settings only; no input files, camera or export destination |
| Recover a trusted old project | Legacy configuration import | A migration starting point that requires field-by-field review, not a lossless modern Scene |

## Save and reopen a Scene

Load and validate the inputs, adjust settings and select **Apply**. Ordinary **Save Scene** JSON keeps references to the original files, verifies their hashes and preserves applied settings with optional camera/export state. It does not copy input data. For another computer, choose **Portable Scene with data (*.zip)** in the save dialog and transfer that ZIP; **Open Scene** reads JSON or ZIP. Portable ZIPs include supported companion files. Keep local data available for ordinary JSON replay. The [local-file guide](M02_Data_Formats_Coordinates.md) describes both choices.

When reopening, review resolved paths, hashes, file roles, spatial alignment and the rendered result. A missing or changed input is a reason to investigate, not to bypass validation. Scene replay can restore supported camera and export preferences, but an old Scene may not express every newer option. [Scene Workflows](../../documentation/Scene_Workflows.en.md) documents the detailed schema, path and command-line behavior.

## Apply a visualization preset

Choose a preset after loading the intended data. Preset load replaces the visualization settings sections; it does not bring in files or preserve pending edits and camera state. Review the resulting controls, then use **Render Scene** for a visible redraw. Save a new Scene JSON if the input-plus-display combination should be reproducible. See [Visualization Presets](../../documentation/Visualization_Presets.en.md) for the supported fields and reset behavior.

## Import a legacy configuration

Use a legacy MAT configuration only when its source is trusted. The migration translates what it can, reports fields requiring review, and may change the rendered appearance. Inspect file roles, paths, layout, thresholds, colors and export options; compare a representative image before adopting the result. Review the translated settings before use. [Migration and troubleshooting](M15_Migration_Troubleshooting.md) lists current limits.

## Batch and provenance

For repeatable non-interactive rendering, use `BrainNetRender` with a reviewed Scene. The Scene JSON, input checks and export provenance help reconstruct a figure but do not replace recording data origin, atlas version, coordinate convention, software build and any manual decisions. [M14](M14_Batch_Provenance.md) covers batch use. Before sharing any Scene, inspect paths, metadata and sidecars for private local information; sharing the JSON never authorizes sharing its referenced data.
