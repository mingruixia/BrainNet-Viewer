# Reusing visualization presets

 Surface Map and
statistical ROI P-value presets now apply when the selected NIfTI has supported
statistic metadata; ROI mode also uses Cluster Size. Custom
ROI palettes are supported by Modern Batch Renderer; preset review reports ID
coverage checks, not an unimplemented feature. An empty table needs correction if
ROIs are selected; rendering rejects any selected ID without a color. Recheck IDs
when switching atlases or statistical thresholds. The current writer uses Settings
schema 1.22.0; the older version notes below are historical migration context.

**Colors...** beside the preset buttons edits custom RGB palettes. Palettes are embedded in applied settings and presets; see [Custom colormaps](Colormaps.en.md). Current settings use schema 1.22.0; older color tables remain readable. Custom boundary masks are geometry-specific, not generic presets; see [Surface boundaries](Surface_Boundaries.en.md) for migration and binding rules.

## Desktop workflow

1. Load your input files or open a Scene JSON.
2. Configure the right-hand **Visualization Settings** sections. Click the single **Apply** at the panel bottom to commit all pending section edits **and render the Scene**; **Revert** there discards all pending edits. The pair remains outside the scrolling section content.
3. Click **Save Preset** just below the settings header. Save a `*.preset.json` file. Only applied settings are saved; the rendered scene remains open.
4. Select another dataset, then click **Load Preset**. Review the confirmation and compatibility notes; select **Apply** or **Cancel**.
5. Check the dataset-specific thresholds, units, color limits and ROI selections, then click **Render Scene**. Interact and export as usual.

Both preset buttons remain available when no data is selected. In that case, compatibility with data is deferred. The buttons hide together with the entire settings panel. They do not add another settings window.

Loading replaces all nine settings sections and discards pending editor changes after confirmation. It retains the current Scene identity, input paths/hashes, coordinate-space declarations and export-panel preferences. It closes the old render and clears its camera; render again to use the current layout's default view. Saving a preset does not change the current scene or canvas.

## Which file should I use?

| File / control | Purpose | Includes data paths? | Includes camera/export preferences? |
|---|---|---|---|
| **Save Scene** / Scene JSON | Reopen one analysis with input references and settings | Yes; referenced files are not bundled | Yes, when saved from the modern App |
| **Save Preset** / preset JSON | Reuse display settings on different data | No input-reference fields | No camera or export-panel session state |
| **Import Settings** / legacy MAT | Explicit conversion of trusted old EC settings | May include legacy File/FLAG inputs when no Scene is selected | Not a modern session snapshot |

Presets retain the `image` settings section (default dimensions/DPI, title and colorbar styling) for contract consistency. These values **do not overwrite the current export panel** when a preset is loaded. Adjust output dimensions and format in **Export Figure**. Presets do not save compute-backend selection or GUI theme.

## Checks and limitations

- The JSON has an explicit kind and schema version. Scene JSON, unknown versions/extra fields, missing sections, invalid settings and explicit input/camera fields are rejected before current settings change.
- Missing input roles and mapped-color prerequisites produce review notes. Inactive sections remain stored; no files are inserted or silently substituted. A role-level check does not establish anatomical registration, scalar units, sensible thresholds or valid ROI labels.
- Fiber rendering blocks preset application. Surface Map and statistical ROI P Value require supported NIfTI statistic metadata at render time; ROI mode also applies Cluster Size. Custom ROI palettes require coverage of selected ROI IDs; warnings require review, and missing required colors prevent rendering.
- Confirmation cancellation preserves applied settings, pending edits and the canvas. A failed read/validation does not replace settings or close a rendered scene. The UI may display an error message.
- User-entered titles, labels and preset names are free text; inspect them for sensitive information before sharing. No automatic upload occurs.

## MATLAB API

```matlab
app = BrainNetViewer;
% Configure and Apply settings in the UI, then:
app.savePresetFile("network.preset.json", Name="Network overview");
[preset, report] = app.inspectPresetFile("network.preset.json"); % Read-only
% After reviewing report.warnings; blockers cannot be bypassed:
app.loadPresetFile("network.preset.json", AllowWarnings=true);
```

`AllowWarnings` defaults to `false`; the API raises `BNV:Preset:ReviewRequired` until the caller explicitly accepts review notes. `Overwrite` defaults to `false` for saving. A blank load path is a no-op cancellation. `brainnet.io.readPreset` / `writePreset` and `brainnet.core.VisualizationPreset` are independent of App graphics and do not read datasets.

The preset schema embeds the existing settings contract. See [Scene workflows](Scene_Workflows.en.md) for complete-session replay and command-line rendering.
