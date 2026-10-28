# Save and reopen a Scene

[Tutorial index](index.md) · [Previous lesson](02_First_Surface_Visualization.md)

Save the rendered surface from lesson 02, reopen it in the same edition, and distinguish a Scene from an appearance preset. A Scene preserves input references and display/session information; a preset reuses appearance on separately selected data. Neither performs registration.

## Prepare the scene

Use the original `BrainMesh_ICBM152.nv`, **Single View**, **Isometric**, **Uniform** gray `[0.85 0.85 0.85]` and **Opacity 1**. Click **Apply**, review the brain, then optionally adjust its camera. Save only after the intended settings have been committed.

## Save with the correct companions

Choose **Save Scene** and a new writable `surface-basics.scene.json` destination. Retain the original data and inspect any warnings. The editions use different portability mechanisms:

| Edition | What to retain |
| --- | --- |
| MATLAB Desktop | JSON references the original local files without copying. For migration, choose **Portable Scene with data (*.zip)** in the save dialog; the ZIP contains the required inputs and companions. |
| Python Desktop | Scene JSON and the copied companion assets folder created beside it. Move/copy the entire bundle, not just the JSON. Keep the originals for analysis. |

Do not rename or hand-edit companion paths/hashes to suppress an error. Save to a new location when an existing file must be preserved. The shared `.json` suffix does not prove Scene exchange between editions; this exercise uses same-edition replay. No prebuilt Scene files are added to the resource distribution.

## Reopen and compare

1. Record the current input identity, color, opacity and layout before reopening.
2. Open a fresh instance of the **same edition**. In **Data Sources → Scene File → Open**, select the saved JSON, or the MATLAB portable ZIP when migrating.
3. Follow its load action; use **Validate and Load** if required by the current interface, then **Render Scene** for an explicit draw. Review loading or camera-compatibility warnings before exporting.
4. Confirm the original 81,924-vertex/163,840-face mesh and Uniform gray/Opacity 1/Single View settings. Check compatible camera and export preferences if saved by the application.

![MATLAB Scene replay with numbered Surface Apply and Save Scene controls](../../assets/captures/manual-revision/03-scene-steps-gray.png)

*MATLAB Desktop illustration from the existing same-edition Scene exercise. Numbered controls show configuration, Apply and Save Scene. It does not demonstrate Python companion-folder packaging or cross-edition replay.*

A compatible saved camera is restored on reopening. If it is incompatible, the application uses the layout cameras and displays a warning. Matching hashes confirm file identity; registration must be checked separately. Screen size, graphics drivers and renderers can affect the image even when inputs and settings match.

## Save appearance separately

For reuse on another dataset, use **Save Preset** rather than Save Scene. Apply and inspect first: **MATLAB saves applied settings**, whereas **Python Save Preset can capture current pending panel edits**. A preset is not a data bundle and does not replace the Scene camera/export session.

Load compatible inputs, choose **Load Preset**, review the controls and click **Apply** to commit and render. Recheck data-dependent thresholds, color limits and ROI IDs. Never assume a preset created for one atlas has meaningful IDs for another. Cross-edition preset exchange is not guaranteed.

## Resolve replay errors

- **Missing inputs:** MATLAB needs the intended configured root and relative files; Python needs the complete JSON/assets bundle. Restore missing files before reopening.
- **Changed input/hash:** use the original input or deliberately save a new Scene after reviewing changed data; do not modify the stored hash merely to pass validation.
- **Wrong JSON type:** open a Scene with Scene File; load a display preset with Load Preset. A `.json` extension alone does not identify its schema.
- **Old figure after edits:** changing controls does not prove a new render. Apply, review the result, then save/export.

Before sharing a Scene, preset or exported figure, review names, titles and metadata for private information and retain the relevant resource credits. Moving a bundle does not publish it automatically.

Continue with [Nodes modules and connectivity](04_Nodes_Modules_and_Connectivity.md).
