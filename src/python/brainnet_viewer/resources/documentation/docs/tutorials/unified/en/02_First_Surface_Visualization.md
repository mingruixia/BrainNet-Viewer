# First surface visualization

[Tutorial index](index.md) · [Previous lesson](01_Installation_and_First_Launch.md) · [Next lesson](03_Scenes_and_Presets.md)

Load the original real ICBM152 surface, render an opaque gray view, change its camera and export a PNG. These are display operations; they do not alter the mesh coordinates or validate registration.

## Input and settings

Use `Data/SurfTemplate/BrainMesh_ICBM152.nv` from your edition's resource library. This original mesh has **81,924 vertices and 163,840 triangular faces**. It is an anatomical template, not a participant scan. Surface credit: **Prof. Alan C. Evans (MNI)**; see the [resource attribution](../../en/Resource_Attribution.md). This lesson does not use the smoothed variant, a vertex map, nodes, edges or a volume.

| Setting | Value |
| --- | --- |
| Layout | Single View |
| View Direction | Isometric |
| Surface Color Mode | Uniform |
| Uniform Color | Gray RGB `[0.85 0.85 0.85]` |
| Surface Opacity | `1` |

## Load the surface

1. In **Data Sources**, use the **Surface Mesh → Add** control or **Add Files** and select the named mesh as the Surface role. Do not open an NV mesh through the Scene JSON control.
2. Select **Validate and Load**. Review the Surface path and counts in the Scene summary. This example should contain one surface and no other scientific inputs.
3. If a previous exercise is loaded, clear its Nodes, Edges, Surface Map and Volume roles before proceeding; clearing only the canvas does not remove inputs.

**MATLAB Desktop:** the bundled mesh is already within its data root. For a copy outside the configured root, follow the **Stage and Add** prompt if offered; cancel rather than substituting a different template.

**Python Desktop:** select the bundled file or your own copy directly. Saving a portable Scene later creates companion assets; MATLAB staging instructions are not the Python save mechanism.

## Configure and render

1. Expand **Layout**, choose **Single View** and **Isometric**.
2. Expand **Surface**, choose **Uniform**, select gray `[0.85 0.85 0.85]`, and set **Opacity** to `1`.
3. Click the single shared **Apply** at the bottom of the settings panel. It commits and renders; a second **Render Scene** click is unnecessary after successful Apply.

![Opaque gray original ICBM152 surface and Surface controls](../../assets/captures/manual-revision/02-gray-surface.png)

*MATLAB Desktop illustration. It shows the real original surface and the shared exercise values, not a Python-rendering acceptance result. Lighting and exact pixels may differ by edition and graphics environment.*

Expect one complete opaque gray brain. A Uniform surface has no statistical scalar colorbar; enabling the surface colorbar does not invent mapped values. To try transparency, change Opacity to `0.3`, Apply, inspect the result, then restore `1` and Apply before the next lesson.

## Adjust the camera

Use **Fit** to frame the visible surface. Select **Rotate**, **Pan** or **Zoom** and manipulate this view, then use **Reset** to restore the layout camera. Camera changes do not change coordinates. For multi-view layouts later, manipulate the intended subplot; these operations do not synchronize every brain.

View Direction is editable for Single View. Selecting a multi-view preset disables this direction choice because that layout supplies its own cameras. A hemisphere-splitting layout requires a separable surface; do not infer two hemispheres for arbitrary geometry.

## Export the first figure

1. After the current surface renders, open **Export Figure** below Data Sources.
2. Choose **PNG**, **Pixels**, width `1600`, height `1200`, and `300 DPI`. Leave **Transparent** off for an opaque canvas background.
3. Click **Export...** or **Export Figure** and save to a new writable `first-view.png`. Close the successful-save message.
4. Open the image and confirm the complete brain is present. Keep `first-view.png.provenance.json` beside it. Review that record before sharing: path handling differs by edition, and names/titles may disclose private information.

These dimensions specify pixels; DPI records output density and is not a promise of added anatomical detail. The interface theme is not the exported scientific background. Export requires a current render. Choose a new destination if you need to preserve an existing image or provenance record.

## Check the result

Confirm the expected mesh counts, one complete brain, applied Uniform/Opacity values and a saved PNG plus sidecar. Treat exact pixel differences as rendering differences unless a specific data/configuration mismatch is established. If a file is missing or changed, resolve it rather than silently swapping templates. Proceed to [Save and reopen a Scene](03_Scenes_and_Presets.md).
