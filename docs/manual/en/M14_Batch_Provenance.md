# M14 · Command-line rendering, batches and provenance

[中文](../zh-CN/M14_Batch_Provenance.md) · [Manual index](index.md) · [Illustrated real-data CLI tutorial](../../tutorials/en/08_Command_Line_and_Scene_Replay.md) · [Real-data performance tutorial](../../tutorials/en/13_Performance_and_Reproducibility.md) · [Scene workflow details](../../documentation/Scene_Workflows.en.md)

Command-line rendering uses the **modern** Scene/renderer without opening the desktop App; it does not replace the historical `BrainNet_MapCfg` signature. A MATLAB license and working graphics environment are still required. This is not a browser/Docker edition.

## Prepare a reproducible Scene

In the desktop, select files, **Validate and Load**, adjust Visualization Settings, and **Apply** (which commits and renders). Use **Save Scene** to create Scene JSON. It records applied settings, relative input references/hashes, coordinate/redistribution metadata, and—when saved by the modern App—optional camera and export-panel state. It does **not** embed source data, accept unapplied edits, certify spatial registration or grant file-sharing rights. The data root is an explicit directory: references resolve relative to that root, not relative to the Scene JSON's folder. If external files are selected in the App, approval stages verified copies under its configured root; a manually written Scene or CLI run does not silently copy outside data.

To render one image without opening the App:

```matlab
record = BrainNetRender("D:/results/scene.json", "D:/results/figure.png", ...
    DataRoot="D:/project-data", ComputeBackend="cpu", ...
    PerformanceMode="quality", Width=2000, Height=1500, ...
    Resolution=300, Overwrite=false);
```

The command reads and validates input files, prepares data, renders a hidden modern figure and writes the image plus `figure.png.provenance.json`. Output extensions are PNG, JPEG, TIFF, BMP, PDF or SVG; complex PDF/SVG scenes may contain rasterized 3-D content. The output file and sidecar are protected from overwrite by default. Use a distinct output name for every run or explicitly choose `Overwrite=true` after checking the targets. A simple MATLAB loop may call `BrainNetRender` over different Scene/output paths; there is no claim of an independent job scheduler or automatic dataset discovery.

## Options to review per run

| Option | Current behavior |
|---|---|
| `DataRoot` | Defaults to the installed BrainNetViewer folder; set it explicitly for portable project data. |
| `ComputeBackend` | `auto` (default), `cpu`, `gpu`; GPU applies only where individual operations support it. |
| `PerformanceMode` | `quality` (default), `interactive`, `auto`. For publication runs, explicitly request quality. |
| `Width`, `Height`, `Resolution`, `Units` | Specify both dimensions or neither. Otherwise saved App export preferences are used, falling back to Scene `image` defaults. Explicit dimensions without Units use pixels. DPI and physical units are interpreted by the exporter. |
| `BackgroundColor`, `ContentType` | Explicit choices override saved preferences. JPEG/BMP cannot use transparent `none`; raster formats reject vector content. Auto/PDF/SVG do not promise pure vectors. |
| `LegacyConfig` | Optional trusted legacy EC MAT conversion before rendering; not a full old-GUI replay or a sandbox for untrusted MAT objects. |
| `Planner` | Optional reusable `brainnet.render.RenderPlanner` object; within one MATLAB process it can reuse preparation work when keys match. It does not prove GPU speedup or identical pixels. |

Scene loading checks input identities/hashes; a changed or missing file should stop instead of silently substituting data. The Scene's optional camera is restored only when its content signature remains compatible; otherwise the layout default is used. For comparisons across machines/versions, review settings, numeric fingerprints, renderer/version and camera records in the provenance JSON; do not require pixel-identical image hashes across graphics drivers. **The sidecar may contain local paths, titles and sensitive metadata**. Review it and input-resource licenses before publication. Nothing is uploaded automatically. For reusable appearance without input paths, use a visualization preset rather than Scene JSON; see [M11](M11_Colormaps_Presets.md).

The [real-data CLI tutorial](../../tutorials/en/08_Command_Line_and_Scene_Replay.md) demonstrates one portable Scene and two output formats. Review sidecar privacy and cross-platform rendering differences for your own project; this chapter is not a Docker deployment guide.
