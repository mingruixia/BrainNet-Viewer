# Migration, limitations and troubleshooting

[中文](../zh-CN/M15_Migration_Troubleshooting.md) · [Manual index](index.md) · [Migration notes](../../documentation/Migration.en.md)

BrainNet Viewer provides a MATLAB desktop workflow. Standalone Runtime-only and Docker/browser editions are not included. This chapter explains supported configuration formats, interaction controls and troubleshooting.

## Moving from BrainNet Viewer 1.7/1.8

| Older workflow | Current route | What to check |
|---|---|---|
| GUIDE main window / Load File | `BrainNetViewer`; Data Sources → Validate and Load | Use the project launcher and an explicit data root. Local files are read directly. JSON saves references; choose a portable ZIP to include data. |
| BrainNet_Option.fig and OK/Apply | Right-hand Visualization Settings → shared **Apply** | Apply commits **and renders**. **Revert** drops pending edits; canvas **Reset** changes only the camera; **Restore Defaults** replaces display settings after confirmation. |
| Save/Load Option MAT | **Save/Load Preset** for display reuse; **Import Settings** for trusted EC MAT | Presets omit inputs/camera/export-panel preferences. An EC import is a reviewed conversion, not guaranteed lossless reproduction; retain the original MAT and inspect `fields_requiring_review`. |
| Save or reopen an analysis | **Save Scene / Open Scene JSON** | Scene records input references/hashes and applied settings, with optional modern camera/export state. Keep the corresponding data-root structure; verify hashes and spatial alignment. |
| Redraw / Clear Figure | **Render Scene** for explicit redraw; **Clear Figure** for view-only clearing | Clearing the figure preserves inputs/settings; a per-role Clear removes that input. |
| Get position | In-canvas **Inspect** | Queries AAL/Brodmann using assumed MNI-like coordinates; it does **not** register or transform the input. Verify provenance before citing regions. |
| Merge Mesh / generate coordinates | **Merge Surfaces**, **Convert Surface to NV**, **Subdivide Surface to NV**, **Generate Nodes from Atlas** | New reviewed files, no silent source overwrite or registration. Conversion is geometry-only; the old `.mesh` implicit coordinate inversion is not retained. |
| Movie / print / script | **Export Animation**, **Export Figure**, `BrainNetRender` | Animation is a static-scene camera orbit. Print from an exported image/PDF externally; the modern CLI is not a drop-in `BrainNet_MapCfg` replacement. |

## Locate familiar menus and interaction tools

The desktop follows one sequence: load files, configure, render, interact and export. **Data Sources** selects and validates the inputs; **Visualization Settings** controls appearance; the central canvas displays the result. **Help** and **About** are in the header. Separate tool windows provide mesh and atlas-node operations.

After rendering, use the canvas **Rotate**, **Pan** and **Zoom** tools rather than MATLAB's old figure-toolbar modes. **Fit** frames the visible geometry; **Reset** returns to the layout's initial camera. **View Direction** supplies Left, Superior, Anterior and opposite/other directions for Single View; the historical instruction to click a standard-view icon twice is not part of this interface. **Inspect** replaces the old Get Position datatip workflow and clears its compact on-canvas label when clicked again. **Live Demo** and **Stop Demo** control an on-screen camera orbit, while **Export Animation** makes a separately configured movie or PNG frame sequence.

The old **Print** button and MATLAB **Plot Edit** figure mode are not present in this App. Export a figure at the required pixel/physical size, then print or annotate it in a suitable external application. Likewise, the old `.mat` Save/Load Option operation is not identical to a modern Scene: choose a visualization preset for reusable appearance or a Scene JSON for reproducible input references and applied settings. The historical `BrainNet_MapCfg` file remains a legacy MATLAB entry point in this development tree, but `BrainNetRender` is the documented modern Scene-based command; do not assume interchangeable argument or provenance behavior.

Modern Settings schema is 1.22.0. Older Scene/preset/EC values may migrate, but their appearance can change because node/edge threshold endpoints, modules, signed volume color handling, ROI numbering/smoothing and other semantics were clarified or repaired. Recheck science-critical settings with a small dataset that independently varies `.node` columns 4 and 5 and includes values exactly at thresholds. Do not use visual similarity alone as proof of parity. For source-specific rules see [Nodes](M07_Nodes.md), [Edges](M08_Edges.md), [Volume](M09_Volume_Mapping.md), [ROI/Inspect](M10_ROI_Inspection.md) and [Colormaps](M11_Colormaps_Presets.md).

## Capabilities and limitations

- The independent NIfTI reader supports NIfTI-1/2 single files and paired headers/images, including supported gzip variants; **pure Analyze 7.5** without NIfTI magic is rejected. MNI/BIC `.obj` is not Wavefront OBJ. FreeSurfer `.pial`, BrainVISA `.mesh`, MZ3 and GIfTI have narrower reader-specific rules. Loading a geometry does not establish coordinate registration.
- ROI **P Value** now converts supported statistical NIfTI metadata but does not infer whether an input is an atlas or statistic map, correct multiple comparisons or prove cluster-level significance. Fiber-tract rendering, arbitrary **Plot Edit**, GIF/EPS/EMF export, native print and Runtime-only packaging are not available/validated in this build. Independent Python Desktop and Docker/Web editions are available; see their installation guides for requirements and differences.
- The current desktop target is Windows MATLAB R2025a Update 1. Other MATLAB versions, platforms, all graphics drivers/monitor DPI combinations and required-toolbox matrices are not fully certified. The startup build date identifies the build and may differ from the release date.
- GPU acceleration is operation-specific, not a promise that all rendering or video encoding runs on GPU. Complex PDF/SVG scenes may be rasterized; JPEG/BMP have no transparent background. PNG/TIFF transparency is conditional on an actual alpha-bearing export. Hashes and provenance identify data/configuration, not anatomical validity, publication rights or pixel identity across systems.

## If something goes wrong

| Symptom | First check / safe action |
|---|---|
| The launcher is not found or a different BrainNet starts | Use the current project root containing `BrainNetViewer.m`, add that root to the MATLAB path if necessary, and remove conflicting path entries from the session; do not alter the original software folder. See [getting started](../../documentation/Getting_Started.en.md). |
| Move a Scene to another computer | In Save Scene select **Portable Scene with data (*.zip)**, transfer the ZIP and use **Open Scene**. Ordinary JSON references the original files; moving it alone does not move those data. |
| Scene/preset JSON fails to open, or files/hashes do not match | Use **Open Scene JSON** for Scene files and **Load Preset** for `*.preset.json`; these schemas are not interchangeable. Check version/required fields, data-root-relative paths, companion files and the original hashes. Do not suppress validation by changing a hash. |
| New file selected but the old image remains / nothing exports | **Validate and Load**, then **Apply** (commits and renders) or explicit **Render Scene**. Export needs a current Modern Batch render. Loading a preset clears the old render, so Render Scene again. Check the Scene summary for retained manual volume limits when changing datasets. |
| Wrong side, scale, or atlas region / empty split view | Check the actual coordinate frame, orientation, units, surface-volume alignment and hemisphere separability. The App does not register data. Use a supported whole-surface layout for an inseparable mesh; treat Inspect's AAL/Brodmann result as provisional. |
| ROI P Value metadata error, unsupported file, or custom color error | Verify NIfTI statistic type/degrees of freedom; do not treat an atlas as a statistic map. Otherwise choose a compatible reader/file or provide every selected ROI ID in the custom color table; see [ROI rules](M10_ROI_Inspection.md). |
| GPU, transparency or animation export fails | Try the documented CPU backend where relevant; verify output format, real alpha support, video codec availability, even video dimensions, frame/size limits and a **new** animation folder. Do not overwrite or publish partial output. |

For an unresolved reproducible failure, record the build/MATLAB version, data roles and non-sensitive dimensions, exact error, minimal steps, compute backend and output format. Keep participant data and absolute provenance paths out of public reports unless authorized. Verify limitations against the actual package before sharing results.
