# Vertex maps boundaries and Inspect

[Tutorial index](index.md) · [Previous lesson](04_Nodes_Modules_and_Connectivity.md)

Display the historical AAL vertex-label table, outline its transitions and query a surface point with the AAL/Brodmann Inspect lookup. A vertex label map assigns a category to each original mesh vertex; it is not a statistical volume or a registration procedure.

## Choose the documented pair

Use `Data/ExampleFiles/AAL90/icbm_vertex_AAL_label.txt` as **Surface Map**. Choose the documented surface for the edition's exercise:

| Edition | Surface Mesh | Demonstration settings |
| --- | --- | --- |
| MATLAB Desktop | `Data/SurfTemplate/BrainMesh_ICBM152_smoothed.nv` | Four views with `jet`, limits `0 90`; then Single View for Inspect |
| Python Desktop | `Data/SurfTemplate/BrainMesh_ICBM152.nv` | Single View with `hsv`; original surface used in the Python exercise |

Both surfaces have 81,924 vertices and 163,840 faces, but their coordinates differ. These are separately documented uses of the historical table, not permission to bind it to any equal-sized surface. Do not substitute Ch2, reorder vertices, subdivide a mesh or assume that a different smoothing/projection preserves correspondence. The labels must remain in the mesh's original vertex order.

The map has **81,924 integer values**, **79 distinct IDs** spanning `0–90`, and **7,352 zero values**. Zero denotes unlabeled/background; “AAL90” does not mean that all 90 positive regions occur on this surface. Map SHA-256: `7cd6b8aa19c2aae6161015d62d22770a1fdfdf61d7e29354e8174dbd7853d131`. The historical AAL table is not the AAL3v2 network example.

The original and smoothed surface resources are credited to **Prof. Alan C. Evans (MNI)**. Retain the [existing paired-resource attribution](../../en/Resource_Attribution.md). This local historical projection does not independently establish the exact source atlas release, projection algorithm or registration accuracy.

## Load and color the labels

1. Clear earlier Nodes, Edges and Volume inputs; retaining them would add unrelated geometry or mapping to this exercise.
2. Add the chosen mesh through **Surface Mesh** and the text table through **Surface Map**, then click **Validate and Load**. Expect one mesh and one map with matching vertex/value counts.
3. Set **Surface → Color Mode → Scalar Map**, **Opacity `1`**, **Boundary → Automatic**, and a black **Boundary Color**. Enable **Show Surface Colorbar**.
4. Apply the edition-specific layout/palette settings below, then click the shared **Apply** to commit and render.

**MATLAB Desktop:** choose **Layout → Lateral / Medial**, **Colormap → jet** and **Color Limits → `0 90`**.

**Python Desktop:** choose **Layout → Single View**, **View Direction → Left (Sagittal)** and **Colormap → hsv**. Review the color limits against the `0–90` IDs; set them explicitly when comparing categorical colors across figures. Python zero or missing NaN map values retain the original surface color; infinity is invalid. The integer table here has no NaN values.

![Historical AAL vertex labels and Automatic boundaries in four views](../../assets/captures/manual-revision/04-aal-four-views.png)

*MATLAB Desktop illustration using the smoothed ICBM152 pair and jet palette. It is not a Python screenshot or a newly captured candidate result. Exact colors and boundary appearance depend on the edition, palette and applied settings.*

The colorbar reports numeric label IDs, not named brain regions, probabilities or effect sizes. ID `90` is not a stronger biological value than ID `10`. Changing a palette changes display colors, not labels. A plausible image alone does not prove mesh/map correspondence.

## Interpret and save boundaries

**Automatic** outlines transitions between displayed classes. Triangle-scale boundaries may look angular; black lines are display geometry, not an independent anatomical segmentation. **Threshold** boundary mode uses a value classification and is not a P-value test. A **Custom Mask** must be binary and matched to the original vertex order; matching its length alone does not prove correspondence.

After rendering an Automatic boundary, use **Tools → Save Boundary** and select a new `.txt` destination. The resulting binary mask has one value per source vertex. A selected-boundary-vertex count is not a count of atlas regions and must not be transferred between different meshes or settings.

**MATLAB Desktop:** the boundary output includes provenance comments; inspect them for local paths before sharing. **Python Desktop:** the current desktop action writes a plain integer mask and requires a new destination. Do not assume it carries MATLAB's provenance comments or overwrite behavior. Keep the mesh identity and settings with your own record if the mask will be reused.

## Inspect a left surface point

1. Retain the same edition-specific mesh/map and Scalar Map settings. Choose **Single View → Left (Sagittal)** and Apply. Use Fit if needed to frame the complete brain.
2. Click **Inspect** on the canvas toolbar, then click a visible colored surface point rather than a boundary line or empty background.
3. Read the selected source vertex and XYZ together with **Brodmann Area** and **AAL region**. Another pick replaces the annotation. Click **Inspect** again to exit and clear it; no separate popup is required.

| Edition | Pick and annotation behavior |
| --- | --- |
| MATLAB Desktop | Surface or node inspection is documented; this exercise picks a surface vertex. The compact label appears inside that view and can include the mapped value. |
| Python Desktop | This action queries a surface vertex and shows a compact annotation above the canvas. It is not a node-inspection demonstration. |

![MATLAB left surface Inspect with dual-atlas lookup](../../assets/captures/tutorial04-aal/04-aal-left-inspect-full-window.png)

*Existing MATLAB Desktop illustration on the smoothed pair. This illustrated pick reports vertex 3, surface value 11, AAL Frontal Inf Oper L and Brodmann Area 48. These are one example's outputs, not prescribed results for an arbitrary mouse click or the original Python mesh. The older screenshot has the colorbar switched off for this Inspect demonstration.*

Inspect selects a source vertex rather than interpolating a complete parcel at the exact cursor location. Edges, arrowheads and ROI meshes are not the targets of this lesson. The surface-label text and the independent volume-based lookup are different information sources; they need not agree everywhere. The temporary Python Inspect annotation is not included in figure export.

## Respect the lookup space

Inspect assumes coordinates already match the lookup tables' MNI frame. It does not apply an affine transform, register native anatomy or verify alignment. Non-human, native-space or otherwise incompatible inputs can return plausible but incorrect anatomical names. Brodmann and AAL are different parcellations and need not have one-to-one region labels. A missing or unexpected lookup is a reason to check coordinates and source data, not to move atlas vertices until a desired name appears.

## Save and check

Save a same-edition Scene after the intended configuration renders, following the [Scene and preset lesson](03_Scenes_and_Presets.md). Preserve MATLAB's referenced root/files or Python's JSON/assets bundle as appropriate. Recheck vertex counts, applied palette, boundary visibility and camera warnings on replay; do not promise identical pixels across renderers.

If no mapped patches appear, confirm the Surface Map role and Scalar Map mode. If counts mismatch, restore the correct pair rather than padding or truncating the table. If Inspect does not identify the intended surface point, check that it is enabled and that the click hits rendered surface geometry. Registration and categorical interpretation must be checked independently of successful loading.

Atlas reference: Tzourio-Mazoyer et al. (2002). Automated anatomical labeling of activations in SPM using a macroscopic anatomical parcellation of the MNI MRI single-subject brain. *NeuroImage* 15:273–289. The historical citation does not determine the exact local projection protocol.

Continue with [Statistical volume to surface mapping](06_Statistical_Volume_to_Surface.md).
