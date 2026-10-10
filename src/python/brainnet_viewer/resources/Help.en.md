# BrainNet Viewer Quick Help

## Basic workflow

1. Add files individually by role or use **Add Files** / drag and drop in **Data Sources**. The bundled surface library opens by default when you add a surface. **Validate and Load** checks the selected inputs and displays paths and sizes in Scene.
2. Open **Layout**, **Global**, **Surface**, **Nodes**, **Edges** or **Volume** in **Visualization Settings**. One section opens at a time; click its heading again to collapse it. Scroll within settings for long sections; opening a section does not automatically jump it to the top. ROI controls are below Surface Mapping in Volume. **Apply** redraws directly; **Render Scene** is another rendering entry. **Revert** restores the last committed settings. Multi-view layouts disable the single-view direction control.
3. Choose **Rotate**, **Pan** or **Zoom** and interact with the active view. **Reset** and **Fit** restore the layout cameras. The view dropdown sets the viewing direction. **Pop Out** moves the canvas to a separate window; close it to return. **Clear Figure** clears the drawing without removing input files.
4. Use **Inspect** and click the surface to query its nearest original vertex. The displayed XYZ is interpreted in the default MNI frame; this tool does not register or transform data. AAL and Brodmann names are approximate direct lookups and should only be interpreted for appropriately aligned data.
5. Set format, output size, units and DPI under **Export Figure** at the bottom left, then export. PNG, JPEG, TIFF, BMP, PDF and SVG are supported. Transparent background is available for supported formats. Light/Dark changes interface styling without changing the scientific canvas background or saved colors.

## Data and scenes

- Scalar Surface Maps use the Surface Uniform Color at zero or missing (NaN) vertices; values and coordinates are not altered. Infinity is invalid. RGB tables must contain finite colors. The Surface colorbar follows the layout, including the gap between anterior/posterior views in Overview. Statistical Threshold supports decimal input and 0.1 steps in Value/Cluster modes; P-value mode computes its threshold.
- Surface / Nodes / Edges / Volume **Colormap → Colors…** edits custom RGB rows. The shared **Colors…** tool offers Target, an RGB table and preview, row count, Generate, Resample and Reverse. Import/export RGB text, CSV or JSON. **Use in Settings** stages changes; choose Apply afterwards to redraw. Cancel retains previous settings. ROI Palette uses a named selector; Custom ROI colors remain in the separate ROI ID/color table.
- Export units include Pixels, Millimetres, Centimetres, Inches and Points. Compact unit labels use mm/cm/in/pt; full names remain in the dropdown and Scene. Conversion uses DPI and preserves pixel dimensions when changing units.
- Nodes Colormap → Colors… edits RGB colors directly. Named palettes start with seven rows; add/remove rows as needed. In Modular mode, rows correspond to sorted unique module order and repeat when fewer colors are supplied. OK updates the pending settings; Cancel leaves them unchanged. Apply/Render is still required to update the scene.
- Single View → Custom enables azimuth/elevation in degrees. Enter both numbers, or leave both empty for the default custom view; no JSON syntax is needed.
- Nodes Colormap → Colors… edits RGB colors directly. Named palettes start with seven rows; add/remove rows as needed. In Modular mode, rows correspond to sorted unique module order and repeat when fewer colors are supplied. OK updates the pending settings; Cancel leaves them unchanged. Apply/Render is still required to update the scene.
- Single View → Custom enables azimuth/elevation in degrees. Enter both numbers, or leave both empty for the default custom view; no JSON syntax is needed.
- Add Nodes and Add Edges start in the bundled atlas-network library. Load matching `*_GroupFC.node`/`*_GroupFC.edge` names; choosing one makes the other picker start in the same folder. The seven examples are AAL3v2 (166 nodes), Glasser360, Power264, Shen278 and Schaefer100/200/400Yeo7. Use Modular node colors and Mapped node size to display modules and connection strength. Atlas sources are listed in `resources/notices/NOTICE_ATLAS_NETWORK_EXAMPLES.md`.
- Add Nodes and Add Edges start in the bundled atlas-network library. Load matching `*_GroupFC.node`/`*_GroupFC.edge` names; choosing one makes the other picker start in the same folder. The seven examples are AAL3v2 (166 nodes), Glasser360, Power264, Shen278 and Schaefer100/200/400Yeo7. Use Modular node colors and Mapped node size to display modules and connection strength. Atlas sources are listed in `resources/notices/NOTICE_ATLAS_NETWORK_EXAMPLES.md`.
- Custom ROI colors use an ROI ID/color table: choose Custom color mode, add unique positive IDs, and click each color button. Remove Selected deletes selected rows. Include a color for every ROI that will be drawn.
- Color limits use Auto or Min/Max numeric fields. Opacity uses an ordered 0–1 pair. Positive/negative volume limits each offer Auto independently; all numeric range fields accept scientific notation.
- ROI Selection accepts positive IDs separated by spaces or commas (for historical AAL, bilateral insula is `29 30`). P-value input accepts scientific notation such as `1e-8`; choose 6, 18 or 26 Neighbors for voxel connectivity.
- Surface files include the bundled BrainNet NV templates and supported GIfTI and FreeSurfer forms. Other supported formats are listed in the Python README.
- Node and edge files must describe the same node order and coordinate frame. The application does not infer registration or reorder data.
- Volume mapping assumes the volume affine is meaningful for the surface coordinate space. Inspect assumes an MNI-like coordinate frame.
- A portable Scene stores settings and copies selected input files beside a new JSON file. Keep the Scene JSON and its accompanying asset folder together.
- Rendering can use substantial graphics memory for dense meshes or many edges. Reduce displayed detail or the number of selected elements if interaction becomes slow.

## Resources and support

The installed package includes the 12 BrainNet surface templates and the AAL/Brodmann lookup tables. Their source credits and scope notes are in **resources/notices** within the installation. Software code is GPL-3.0-or-later; the resource notices describe separate data provenance.

The full illustrated manual, shared tutorials and bilingual installation instructions are bundled under resources/documentation/docs. Open User Manual PDF or User Manual Chapters in Help for the common workflow and edition-specific details.
## Bundled real-data tutorials

Select **Real-data Tutorials** in this Help window for AAL vertex mapping and
Inspect, PCC statistical volume mapping, bilateral insula ROI and a group
network example. Files are included in the installed resource library.

## Image provenance and batch export

Saving a figure also saves its `.provenance.json` record, containing data hashes,
display settings, views, export parameters and software versions. Keep it with
the image. Existing images or records require replacement confirmation.
The CLI `brainnet-render --scene example.json --output figure.png` renders a
user-created Scene without opening the desktop; use `--data-root` when needed.
No Scene examples are included. Off-screen VTK graphics support is required.


