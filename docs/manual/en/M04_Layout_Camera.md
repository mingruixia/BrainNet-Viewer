# M04 · Layout and camera controls

[中文](../zh-CN/M04_Layout_Camera.md) · [Manual index](index.md) · [Layout 2 details](../../documentation/Layout_2.en.md)

Use **Visualization Settings → Layout** to choose a view arrangement and initial camera direction. The shared **Apply** commits changes and renders; **Revert** discards pending edits. Saved Scenes and presets retain applied layout settings, but presets do not carry the current camera.

| Control | New-settings default | Effect and when to use it |
|---|---|---|
| **Layout Preset** | **Single View** | Five choices: Single View; Overview (6 / 8 Views); Lateral / Medial; Lateral / Medial / Ventral; Lateral / Medial / Dorsal. Multi-view presets set their own pane directions and use a shared scale; they are not independent copies of the single-view direction control. |
| **View Direction** | **Left (Sagittal)** | Single-view directions: Left, Superior, Anterior, Custom, Right, Inferior, Posterior, Isometric. In multi-view, the preset's own directions take precedence. A named view is a camera orientation, not proof of anatomical L/R. |
| **Custom Azimuth** | no explicit value | Enabled for Custom direction; numeric degrees, −360 to 360. Save and replay the applied value in Scene/preset. |
| **Custom Elevation** | no explicit value | Enabled for Custom direction; numeric degrees, −90 to 90. |

## Read a multi-view figure

Single View is best for adjusting one camera or inspecting one selected point. The lateral/medial arrangement places the outside and inside of each separable hemisphere in four panes. The ventral variant adds inferior views; the dorsal variant adds a superior overview. **Overview (6 / 8 Views)** provides a broader orientation survey: a safely separable two-hemisphere mesh can use eight panes, while a single or inseparable surface uses six complete-data views. Choosing a multi-view preset is not the same as loading multiple independent datasets: every pane represents the same Scene from another camera.

The layout gallery illustrates the available viewing arrangements. Verify the dataset coordinate convention before interpreting orientation labels. At the intended export size, check that labels and thin edges remain legible in the smaller panes.

**Overview (6 / 8 Views)** uses eight split views only when a surface can be safely partitioned into nonempty, vertex-disjoint X-side groups. Otherwise it shows six complete-data views and does not invent a missing hemisphere. This conservative rule does not segment arbitrary anatomy or verify registration. A saved eight-view camera is reset with a notice if replay resolves to six views, and conversely; see [Layout 2](../../documentation/Layout_2.en.md).

If the X-side groups share vertices, the renderer also checks for exactly two disconnected components, each with at least 95% of its referenced vertices on an opposite X side. This supports paired FreeSurfer hemispheres whose medial vertices cross X=0 locally. Each component remains intact; no triangles are cut at the midline. Continuous, single-component or ambiguous meshes still use complete-surface views.

With **Zoom** active, use the wheel over a brain view to zoom that view alone; scrolling over other panels does not change the brain camera. Wheel zoom changes the camera angle, not the axes dimensions.

After rendering, use the canvas controls to **Rotate**, **Pan**, **Zoom**, **Fit**, or **Reset**. Fit recenters and frames visible geometry without changing input coordinates; Reset restores the selected layout's initial camera. Resizing preserves the current camera rather than silently fitting it. **Pop Out** opens an independent inspection copy; later movement there does not replace the main canvas camera. **Save Scene** records a valid modern main-canvas camera; **Save Preset** does not. See [camera/replay details](../../documentation/Scene_Workflows.en.md) and [window sizing](../../documentation/Window_Layout.en.md).

**Double Brain** (described in M06) is a separate single-view display option, not a sixth layout. It is restricted to Left, Superior or Anterior direction with a surface and no scalar-map/volume input. The pane badges governed by **Show Orientation Labels** are described in M05; they identify coordinate halves unless an input-bound anatomical declaration has been explicitly verified.

Multi-view readability depends on mesh shape, labels and display scaling. Check the final figure at its intended export size.
