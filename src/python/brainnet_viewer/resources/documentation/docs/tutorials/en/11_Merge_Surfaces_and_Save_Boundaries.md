# 11 · Merge surfaces and save a boundary mask

[中文](../zh-CN/11_Merge_Surfaces_and_Save_Boundaries.md) · [Tutorial index](index.md) · [Mesh tools](../../manual/en/M13_Surface_Tools.md) · [Boundary semantics](../../documentation/Surface_Boundaries.en.md)

This exercise has **two separate workflows**. First, merge the left/right derivatives of the smoothed ICBM152 surface. Second, export an AAL-label boundary on the **original matched full smoothed mesh**, not on the merge output. Prof. Alan C. Evans (MNI) must be credited for the source surface and derivatives; cite Tzourio-Mazoyer et al., *NeuroImage* 15:273–289 (2002) for AAL.  

## Step 01 · Review the two hemisphere inputs

Open **Tools → Merge Surfaces...**. Click **Add Files...** and choose, in order, `Data/SurfTemplate/BrainMesh_ICBM152Left_smoothed.nv` and `Data/SurfTemplate/BrainMesh_ICBM152Right_smoothed.nv`. Input review appears automatically. The focused R2025a check found **40,962 vertices per half** and **81,924 vertices / 163,840 triangles** in the concatenation. Inspect both hashes, bounds and component ranges before saving. These two files are derivatives of the same ICBM152 template; do not infer that unrelated meshes share a frame merely because names look similar.

![Real left/right ICBM152 derivatives in the Merge Surfaces review window](../assets/captures/tutorial11-merge-boundary/11-merge-review.png)

*Current-build English review window. Local absolute paths are replaced by basenames **only in this screenshot**; the real input review and output provenance retain full paths. No transform or registration is applied.*

## Step 02 · Save a new combined mesh

For this exact pair, optionally enter **Space** `ICBM152 source template frame`, **Units** `mm`, and **Note** `Same template derivatives; no transform.` These fields may be left blank; no verification checkbox is required. Click **Save New .nv...** and select a **new** `.nv` path. This declaration records the source-template understanding; it does not independently validate registration. Load the new file explicitly through **Data Sources → Surface Mesh** if you want to view it; saving alone does not replace the current Scene. The screenshots predate this control simplification; the geometry and review information are unchanged.

The merged mesh has the **same set of vertex coordinates** as the original full smoothed mesh in this pair, but not the same vertex order. Merge does not weld vertices or transfer per-vertex labels, colors or maps. Do **not** attach `icbm_vertex_AAL_label.txt` to this newly merged `.nv` merely because both have 81,924 vertices: the table was prepared for the original full mesh's order. An explicit checked reindexing would be required.

## Step 03 · Save a boundary on the matched original pair

In the main App, load `Data/SurfTemplate/BrainMesh_ICBM152_smoothed.nv` as **Surface Mesh** and `Data/ExampleFiles/AAL90/icbm_vertex_AAL_label.txt` as **Surface Map**. These are the [verified Tutorial 04 pair](04_Vertex_Maps_and_Boundaries.md), not the new merged file. Click **Validate and Load**. In **Visualization Settings → Surface**, choose **Scalar Map**, **Opacity 1**, **Colormap Jet**, **Color Limits `0 90`**, **Boundary Automatic**, **Boundary Color black**, and turn **Show Surface Colorbar** off because region IDs are categories. Click the shared **Apply**. Then choose **Tools → Save Surface Boundary...** and a new `.txt` filename.

![AAL vertex labels with automatic boundaries on the matched smoothed ICBM152 mesh](../assets/captures/tutorial04-aal/04-aal-map-full-window.png)

*Reused current-build Tutorial 04 capture of the exact matched pair; it does not depict the newly merged output.*

 The file includes provenance comments; inspect local paths before sharing. A boundary mask is tied to the original vertex order, not an atlas region list or a geometric isoline. The tool saves data without modifying the active Scene.

## Checks and limits

- Wrong input order changes merged face/vertex ranges. Review and, if needed, **Move Up / Move Down** before saving.
- No merge output is overwritten. Use a new path rather than replacing a prior scientific result.
- An AAL map on a reordered mesh can look plausible while being anatomically wrong. Match the original surface and map hashes; count equality alone is insufficient.
- Automatic boundary marks categorical transitions on the mesh. It is not a statistical threshold, spatial registration check or validation of the historical AAL projection.
