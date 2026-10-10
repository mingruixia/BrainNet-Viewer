# Surface and atlas tools

Use Merge, Convert, Subdivide and Atlas Nodes to write new geometry files without replacing the inputs or active Scene. This lesson uses real ICBM152 meshes and the historical AAL atlas. Boundary export is a separate operation on an exactly matched mesh and vertex map.

In MATLAB Desktop, open the named command from **Tools**. In Python Desktop, use the corresponding **Merge**, **Convert**, **Subdivide**, **Atlas Nodes** or **Save Boundary** button. A successful conversion does not establish registration, coordinate units or vertex-map correspondence.

## Merge the matching hemispheres

Use the installed library's `Data/SurfTemplate/BrainMesh_ICBM152Left_smoothed.nv` and `BrainMesh_ICBM152Right_smoothed.nv`. In Python, library paths are relative to the installed `resources` folder. Credit Prof. Alan C. Evans, MNI, for the source surface and its derivatives.

1. Open Merge and select **Add Files**. Add the left file first and the right file second. Input review appears automatically; use Move Up/Down if the order is wrong.
2. Review the two inputs and counts: each half has 40,962 vertices and 81,920 faces; concatenation has 81,924 vertices and 163,840 faces. Check the source identities and coordinate bounds where shown.
3. Save to a new `.nv` filename outside the installed library. MATLAB uses **Save New .nv...**; Python uses **Save NV**. Existing destinations are not replaced.
4. Load the new file explicitly as Surface Mesh and render it. Saving alone does not replace the current Scene.

**MATLAB Desktop:** Space, Units and Note are optional. For this known pair, they can record the source template frame and millimetres; leaving them blank does not prevent Merge. No separate verification checkbox is required.

**Python Desktop:** optional Space, Units and Note controls do not affect geometry or block saving. The current publishing implementation records source identities rather than persisting those free-text entries; retain any needed interpretation separately.

![Historical MATLAB review of the matching ICBM152 hemispheres](../../assets/captures/tutorial11-merge-boundary/11-merge-review.png)

MATLAB Merge illustration. Add automatically reviews the inputs; no verification checkbox is required. Review/output metadata may contain full source paths.

The merged vertices have the same coordinates as this pair's original full smoothed mesh, but their order differs. Do not attach `icbm_vertex_AAL_label.txt` to the merged mesh merely because its length matches. Merge concatenates coordinates and offsets face indices; it does not weld coincident vertices, register anatomy or transfer scalar/RGB attributes.

For your own FreeSurfer data, merge compatible `lh.pial` and `rh.pial` from the same reconstruction in left-then-right order. A per-vertex map must use exactly that order. Stored surface coordinates do not become MNI coordinates: MNI volume mapping and dual-atlas Inspect require independently verified alignment. One hemisphere alone does not create its missing counterpart.

## Convert one surface to NV

Open Convert and add one supported surface. For a simple exercise, use the original `Data/SurfTemplate/BrainMesh_ICBM152.nv`, then save a new `icbm152-copy.nv`. This exercises the reviewed save path; it is not a new anatomical template. Review appears automatically after adding the file.

For another format, first check the reader's [format restrictions](../../../compatibility/Surface_Format_Support.md) and the edition's file picker. `.obj` here means MNI/BIC polygon data, not arbitrary Wavefront OBJ; `.mesh` does not mean every mesh encoding. FreeSurfer/GIfTI coordinates are not silently registered to MNI. Conversion preserves geometry and vertex order as returned by the reader; it does not automatically transfer appearance arrays or apply dataset-specific coordinate inversions.

Load the output explicitly and compare counts, bounds and anatomy with the input. Reuse a vertex map only if the original correspondence is preserved and checked. Equal counts alone are insufficient.

## Subdivide with one linear midpoint level

1. Open Subdivide and choose the original ICBM152 mesh. Set **Subdivision Levels** to `1` and review the current input/options. Python uses **Review Surface**; MATLAB uses **Review**.
2. Inspect the predicted geometry. Each original triangle becomes four; for the 163,840-face ICBM152 mesh, level 1 predicts 655,360 faces. Levels 2 and 3 multiply the original face count by 16 and 64.
3. Confirm that vertex attributes will not be transferred, then save with **Save New .nv...** to a new filename. Space/unit declarations are optional here and do not transform geometry.
4. Load the denser mesh separately. Do not load the old AAL vertex table onto it; new vertices require new correspondence.

This is linear midpoint refinement, not smoothing, registration or additional anatomical measurement. The documented geometry limits are five million vertices and ten million triangles; memory requirements can still be substantial. Keep this exercise at one level. If you change input or levels after review, review again before saving.

## Generate two nodes from the historical AAL atlas

Use `Data/ExampleFiles/AAL90/aal.nii`, not AAL3v2. The following IDs are the same historical bilateral insula labels used in [lesson 07](07_AAL_Insula_ROIs.md).

1. Open Atlas Nodes in Python, or **Generate Nodes from Atlas...** in MATLAB. Choose the historical AAL NIfTI file.
2. Enter Region IDs `29,30` in that order. Set **Color / Module** to `1` and **Size Value** to `1` in Python; use the corresponding Color/module and Size controls in MATLAB. These are constants for this exercise, not estimates from connectivity.
3. Select **Review Atlas**. Review the two labels, voxel counts, atlas affine and output coordinates. The tool accepts a discrete integer label atlas, not a probability or statistical map. IDs are separated by spaces or commas, not range expressions.
4. Declare the known atlas affine space and units, for this atlas MNI and millimetres, and confirm that you checked them. Python calls the fields **Affine Space** and **Affine Units**. These declarations are required before Python atlas-node saving; follow MATLAB's corresponding reviewed declaration/confirmation step. Do not transfer Merge's optional-input rule to this operation.
5. Save a new `.node`, then load it explicitly with the compatible original ICBM152 surface. Remove any unrelated edge input. Choose Uniform node size if necessary to display the two markers clearly.

Each node is the unweighted mean of its region's voxel centres expressed through the atlas affine. A concave or disconnected region's centroid can lie outside that region. No snapping, region-name lookup, MNI conversion, module detection or connection-strength calculation is performed.

The output rows use `X Y Z module size label`, with the numeric atlas ID as label. Both rows should carry module `1` and size value `1` for this exercise. An accompanying edge matrix must follow exactly the same selected region order; do not attach the bundled 90- or 100-node network to these two nodes. For real prepared networks, return to [lesson 04](04_Nodes_Modules_and_Connectivity.md).

## Save a boundary from the original matched mesh

Follow [lesson 05](05_Vertex_Maps_Boundaries_and_Inspect.md) using its exact edition-specific original mesh/AAL vertex-map pair, not the newly merged or subdivided file. Render Automatic boundaries, then choose Save Boundary and a new `.txt` destination.

The output has one binary value per source vertex, not one value per atlas region. MATLAB includes provenance comments; Python's current desktop action writes a plain integer mask. Retain the mesh identity and settings with the Python mask. A boundary-vertex count depends on the exact mesh, labels and applied configuration and is not prescribed here.

## Keep originals and inspect metadata

Use new filenames and keep original inputs unchanged. Reviewed mesh/node outputs can include provenance comments with source paths and hashes; inspect them before sharing. Python's optional Merge text is not guaranteed in those comments, and plain boundary output is a separate case.

If Save is disabled, check input count, completed review and the tool's specific confirmation requirement. If sources change after review, review the new inputs rather than bypassing identity checks. Do not resolve a correspondence error by padding, truncating or reordering labels without a verified mapping.

Atlas reference: Tzourio-Mazoyer et al. (2002). Automated anatomical labeling of activations in SPM using a macroscopic anatomical parcellation of the MNI MRI single-subject brain. *NeuroImage* 15:273–289. The atlas-centroid exercise does not recreate the prepared group-level connectivity examples.

Next: [camera animation of a static brain scene](12_Camera_Animation.md).
