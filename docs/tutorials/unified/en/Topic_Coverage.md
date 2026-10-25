# Tutorial topic coverage

Use this map to find a shared workflow and its edition-specific instructions. Follow the actual lesson before using a dataset or copying a command.

| Topic and shared lesson | MATLAB Desktop distinction | Python Desktop distinction |
| --- | --- | --- |
| [Installation and launch](01_Installation_and_First_Launch.md) | Licensed MATLAB and software path | Separate Python environment, desktop dependencies and installed entry point |
| [First surface](02_First_Surface_Visualization.md) | MATLAB data-root/loading workflow | Installed resources and Apply rendering |
| [Scenes and presets](03_Scenes_and_Presets.md) | References resolve against configured data root | JSON and companion assets remain together |
| [Nodes and connectivity](04_Nodes_Modules_and_Connectivity.md) | Follow edition-specific selection/color controls | Follow edition-specific selection/color controls; paired input order remains essential |
| [Vertex maps boundaries and Inspect](05_Vertex_Maps_Boundaries_and_Inspect.md) | Documented smoothed mesh pairing; boundary provenance comments | Documented original mesh pairing; plain boundary mask and annotation above canvas |
| [Statistical surface mapping](06_Statistical_Volume_to_Surface.md) | Metadata/P and algorithm controls; numerical GPU scope is limited | Metadata/P and algorithm controls; current numerical mapping is CPU-based |
| [AAL insula ROIs](07_AAL_Insula_ROIs.md) | Follow MATLAB ROI controls and exact historical atlas IDs | Follow Python ROI palette/legend controls and same historical atlas IDs |
| [Layouts and figure export](08_Layouts_and_Figure_Export.md) | MATLAB formats, preferences and provenance behavior | Python physical-unit conversion, vector-container limits and restoration behavior |
| [Custom colors and presets](09_Custom_Colors_and_Presets.md) | JSON object schema; Preset captures applied settings | JSON array schema; Preset can capture current panel edits |
| [Command-line replay](10_Command_Line_Scene_Replay.md) | BrainNetRender, explicit root, lowercase pixels and Resolution | brainnet-render, companion root, Pixels and dpi; saved units otherwise can apply |
| [Surface and atlas tools](11_Surface_and_Atlas_Tools.md) | Reviewed declarations and tool output metadata | Optional Merge text is not persisted; Atlas Nodes requires affine declaration/confirmation |
| [Camera animation](12_Camera_Animation.md) | VideoWriter profile availability | FFmpeg encoder availability; same static-data interpretation |
| [Performance and reproducibility](13_Performance_and_Reproducibility.md) | Historical kernel measurements remain MATLAB-specific | GPU graphics are not evidence of GPU numerical mapping |

Both editions retain the core workflow: open the main window, select inputs, configure, Apply/render, interact, then save/export. Shared scientific examples do not imply interchangeable Scene schemas or pixel-identical rendering. Vertex order, coordinate frame and atlas version must be checked independently of successful loading.

## Further reading and supported features

Start with the [tutorial index](index.md) for the shared workflow. The [manual](../../../manual/en/index.md) provides the illustrated English Word/PDF edition and links to edition-specific reference chapters.

Create your own Scenes as you work through the lessons; prebuilt Scenes are not included. Lesson 01 and the installation guide cover Docker/Web deployment. This version does not provide time-varying connectivity, AI tools or fiber tracking.

## Docker/Web edition

The shared scientific inputs and settings also apply to Web. Select bundled
resources or upload local files. Apply renders remotely; camera tools target
the selected view. Mesh tools and camera animation run in the container.
Scene save/open uses portable ZIP files, while Export Figure downloads an image
and sidecar separately. Colormap rows can be entered in the Web settings.
Command-line rendering in lesson 10 is a desktop/source workflow, not a browser
command. The supplied Web service has one shared session and uses CPU rendering.
See the [Docker installation guide](../../../web/en/INSTALLATION.md).
