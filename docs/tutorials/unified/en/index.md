# BrainNet Viewer tutorials

These tutorials cover MATLAB Desktop, Python Desktop and Docker/Web. They use the same scientific inputs and core workflow, with separate instructions where installation or behavior differs. Start with lesson 01, then load a surface and save your first Scene.

| Lesson | Goal | Input |
| --- | --- | --- |
| [01 Install and first launch](01_Installation_and_First_Launch.md) | Choose an edition, launch and find the controls | Installed application |
| [02 First surface visualization](02_First_Surface_Visualization.md) | Load anatomy, set appearance, interact and export | Original ICBM152 surface |
| [03 Save and reopen a Scene](03_Scenes_and_Presets.md) | Preserve inputs and appearance without confusing a Scene with a preset | Surface from lesson 02 |
| [04 Nodes modules and connectivity](04_Nodes_Modules_and_Connectivity.md) | Encode regional size/color and select network connections | Matched Schaefer100 network; separate original AAL90 example |
| [05 Vertex maps boundaries and Inspect](05_Vertex_Maps_Boundaries_and_Inspect.md) | Display categorical labels and query dual-atlas anatomy | Historical AAL vertex table with the documented mesh for each edition |
| [06 Statistical volume to surface mapping](06_Statistical_Volume_to_Surface.md) | Apply a metadata-derived P threshold and compare sampling | Real PCC one-sample T map |
| [07 Bilateral insula ROIs from AAL](07_AAL_Insula_ROIs.md) | Select categorical regions and adjust colors/smoothing | Historical AAL IDs 29/30 |
| [08 Multi view layouts and figure export](08_Layouts_and_Figure_Export.md) | Choose complementary views and explicit output dimensions | Real PCC map from lesson 06 |
| [09 Custom colors and display presets](09_Custom_Colors_and_Presets.md) | Import RGB rows and replay same-edition appearance | PCC map and shared five-row RGB text |
| [10 Command-line Scene replay](10_Command_Line_Scene_Replay.md) | Render a saved Scene with explicit roots, units and output protection | Your own same-edition PCC Scene |
| [11 Surface and atlas tools](11_Surface_and_Atlas_Tools.md) | Merge, convert, subdivide and generate atlas centroids without losing correspondence | Original ICBM152 meshes and historical AAL atlas |
| [12 Camera animation](12_Camera_Animation.md) | Inspect a short orbit before encoding a presentation movie | Real smoothed ICBM152 surface |
| [13 Performance and reproducibility](13_Performance_and_Reproducibility.md) | Separate processing costs and preserve a repeatable figure | Real PCC map and explicitly identified ICBM152 mesh |

Each illustration identifies the edition shown. Create and save your own Scenes during the exercises. Before interpreting results from your own data, check spatial registration and the statistical method independently of these display operations.
