# 01 · Surface color, opacity and view

[中文](../zh-CN/01_Surface_Basics.md) · [Tutorial index](index.md) · [Surface controls](../../manual/en/M06_Surface.md) · [Camera controls](../../manual/en/M04_Layout_Camera.md)

Change the ICBM152 surface's uniform color and opacity, frame it, then save and reopen the Scene.

## Shared input and parameters

Use the **same** [`BrainMesh_ICBM152.nv`](../../../src/matlab/BrainNetViewer/Data/SurfTemplate/BrainMesh_ICBM152.nv) as [tutorial 00](00_First_Launch.md), SHA-256 `471e43f955a1cb9f0350aaca2822f02fc74e393718d1e385fddaf0e578ffe572`. It has 81,924 vertices and 163,840 faces and is already under the App data root. See its [provider, coordinate and rights note](Resource_Attribution.md). Use the same Windows/R2025a Update 1 internal build as tutorial 00. Time and memory are not yet measured.

| Control | Exercise value | Expected role |
|---|---|---|
| **Layout Preset** | Single View | One camera pane |
| **View Direction** | Isometric | Three-dimensional camera angle; not a registration check |
| **Color Mode** | Uniform | One color over the entire mesh |
| **Uniform Color** | Gray `[0.85 0.85 0.85]` | Appearance only; record RGB for repeatability |
| **Opacity** | 1 | Opaque display; not a change to geometry or data |

## Steps

### Step 01

Launch with `app = BrainNetViewer;` from the project root. In **Data Sources → Add Files**, select `Data/SurfTemplate/BrainMesh_ICBM152.nv` as **Surface**; no staging prompt is expected for this in-root file. Click **Validate and Load**. Expected: one loaded 81,924-vertex surface, no nodes/edges/map/volume.

### Step 02

In **Layout**, choose **Single View → Isometric**. In **Surface**, choose **Uniform**, gray RGB `[0.85 0.85 0.85]`, and **Opacity 1**. Click **Apply** to commit and render an opaque gray surface.

![Opaque gray ICBM152 surface](../assets/captures/manual-revision/02-gray-surface.png)

*Current-build full-window capture; Surface settings are visible. Surface provided by Prof. Alan C. Evans (MNI).*

### Step 03

Use **Fit** on the canvas to frame the surface; optionally try **Rotate** and then **Fit** again. These actions change the camera, not coordinates or stored surface data. The view direction is meaningful for this real-brain template, but this tutorial does not independently verify its registration. If you change **View Direction** afterward, click **Apply** to commit the new setting before saving.

### Step 04

Click **Save Scene** and write a new `surface-basics.scene.json`. It records input references/hashes and *applied* settings and may store the valid main-canvas camera; it does **not** embed the `.nv` data. Keep the template available under the same data root. **Save Preset** is not a substitute here: presets omit input paths and current camera.

### Step 05

Use **Scene File → Open** to select that Scene, then **Load Data → Render Scene**. Expect the same mesh and Uniform/1 settings. Resolve missing-file or camera-compatibility warnings before reuse. Export only after the current Scene renders.

![Reopened gray Scene with numbered Surface, Apply and Save Scene controls](../assets/captures/manual-revision/03-scene-steps-gray.png)

*Scene replay in a fresh App instance; the file path shown in the UI is a display alias, not a change to the saved input reference.*

## Checks, errors and pending figures

- Confirm one real-brain surface, 81,924 vertices and 163,840 faces; the new color and transparency are visible. Do not compare RGB pixel values across renderers or treat the figure as registration validation.
- **Scalar Map** requires a compatible vertex map; changing Color Mode alone does not invent data. Keep **Uniform** for this exercise.
- A missing template `.nv` or changed hash should stop Scene replay; do not silently substitute another mesh. If a camera is reset for compatibility, record that rather than calling replay pixel-identical.
