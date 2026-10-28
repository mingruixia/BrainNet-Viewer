# Data roles, formats and coordinates

[中文](../zh-CN/M02_Data_Formats_Coordinates.md) · [Manual index](index.md) · [Surface format matrix](../../compatibility/Surface_Format_Support.md) · [Data-root workflow](../../documentation/Getting_Started.en.md)

Choose a file's **role**, not just its extension. In **Data Sources**, **Add Files** can classify candidates; use the individual slots when classification is ambiguous. **Validate and Load** reads and checks the selected combination before a figure is interpreted. The default desktop data root is `src/matlab/BrainNetViewer`, not the Scene JSON's folder.

| Role in Data Sources | Typical input | Key correspondence rule |
|---|---|---|
| **Surface Mesh** | `.nv`, `.gii/.gii.gz`, `.pial`, `.mesh`, `.g`, MNI/BIC `.obj`, `.mz3/.mz3.gz` | Geometry supplies XYZ and faces; a readable surface alone does not define MNI/subject space. See [M13](M13_Surface_Tools.md). |
| **Nodes** | BrainNet `.node` | Each row is a marker with coordinates and display fields. Preserve row order when pairing with an edge matrix; illustrative columns are not automatically measured quantities. See [M07](M07_Nodes.md). |
| **Edges** | BrainNet `.edge` | Matrix rows/columns must correspond to node rows; directedness and threshold semantics depend on settings. See [M08](M08_Edges.md). |
| **Surface Map** | Original-order per-vertex scalar text | One value per mesh vertex in the **same vertex order**. Equal length does not prove atlas correspondence; see [M06](M06_Surface.md). |
| **Volume** | NIfTI-1/2 `.nii/.nii.gz` or supported paired `.hdr/.img` | Header/affine and statistic metadata matter. A readable volume need not be registered to a separate surface; see [M09](M09_Volume_Mapping.md) and [M10](M10_ROI_Inspection.md). |
| **Scene File** | Modern `.scene.json` | An analysis reference, not a mesh or volume; its files are resolved under the configured data root. See [M03](M03_Scenes_Presets_Legacy.md). |

## Choose a useful input combination

You do not need to load every role for every figure. A surface alone shows geometry; nodes alone show spatial markers; adding an edge matrix to nodes shows a network without an anatomical mesh. Combining a surface with nodes or with nodes and edges places those elements over anatomy. A scalar surface map or a volume-derived surface map requires a matching surface. The resulting map can also be shown with nodes and edges. To draw atlas or statistical ROIs, load a suitable volume and choose the ROI Volume Type; a surface makes their anatomical context easier to judge. An edge file without its matching nodes cannot establish endpoint locations.

The nine examples below illustrate the different input combinations. For an analysis, start with the fewest data roles needed and add one file at a time. After each addition, inspect the Scene Summary and check that the layers are spatially consistent. Colors and camera positions can be adjusted independently of the input data.

## Prepare text-based inputs

The BrainNet `.nv` format begins with an integer vertex count, then that many XYZ coordinate triplets, an integer triangle count, and that many triplets of **one-based** vertex indices. The number of coordinates and faces must agree with the declared counts. A `#` comment may document provenance, but it does not change coordinates or supply a registration transform. Mesh utilities in Chapter 13 can create a new `.nv` from supported formats after a review step.

A `.node` file has one node per line: `X Y Z color_or_module size label`. The first five fields must be finite numbers; the final label may contain spaces. A label consisting of `-` means no visible label. Column 4 may encode a continuous color value or a discrete module ID, depending on the Nodes color setting; column 5 controls mapped or raw radius. The following three rows are a **format example only**, not atlas coordinates:

```text
0 0 0 1 2 Region_A
10 0 0 2 3 Region_B
0 10 0 2 1 Region_C
```

The matching `.edge` file is a whitespace-delimited 3×3 numeric matrix in precisely the same node order. For example, the first row below describes values from Region_A to Regions A, B and C:

```text
0   0.4 0
0.4 0   -0.2
0   -0.2 0
```

Zero denotes an absent edge. In undirected mode, only eligible upper-triangle entries are drawn; in directed mode, ordered off-diagonal entries can be drawn separately. A file may contain `#` comments. Do not treat this illustrative matrix as a real functional-connectivity estimate. For a per-vertex text Surface Map, provide exactly one finite scalar per vertex in the mesh's **original vertex order**; a matching count without a trustworthy vertex correspondence is insufficient.

Atlas families are not interchangeable node orders or coordinate spaces. Check the package's file inventory, attribution and each sample's node count before pairing any `.node` with an `.edge`. Do not infer that a numerical atlas ID is a statistical effect size.

The independent modern NIfTI/GIfTI readers do **not** require SPM. Plain Analyze 7.5 `.hdr/.img` lacking NIfTI magic is not accepted. GIfTI external binary arrays are supported within the reader's validation rules; keep companions together when moving data. For surface formats, `.obj` means **MNI/BIC**, not Wavefront; `.mesh` means the supported BrainVISA encoding, not arbitrary Medit data. FreeSurfer `.pial` geometry is kept in stored surface coordinates; it is not automatically scanner-RAS or MNI. BrainVISA geometry is kept as stored rather than applying the old implicit XYZ inversion. GIfTI transforms/metadata may be recorded without applying registration. Format support does not imply that embedded MZ3 scalars/RGBA are automatically used for display. Consult the [detailed matrix](../../compatibility/Surface_Format_Support.md) and [M13](M13_Surface_Tools.md) for explicit rejections.

## Local files and portable Scenes

MATLAB opens selected local files directly at their original locations, without an import confirmation or automatic copies. Ordinary **Save Scene** JSON stores file references and hashes; it does not include the data. Keep those files at their recorded locations. For sharing or moving a project, select **Portable Scene with data (*.zip)** in the Save Scene dialog. The ZIP contains the inputs and supported paired or external data files. Open it with **Open Scene** on the destination computer. Older root-relative Scene JSON remains readable. A local JSON containing absolute references is intended for the same computer; use a ZIP when paths will change.

## Scientific alignment check

Before combining inputs, identify species/template or subject, XYZ convention and handedness, physical units, surface vertex order, volume affine, and atlas/statistic meaning. Volume mapping may use the NIfTI affine to sample voxels, but **does not register two datasets**. Inspect assumes compatible MNI-like coordinates for its AAL/Brodmann lookup and does not perform an affine registration. A file hash establishes identity, not spatial alignment, license clearance or statistical validity. If any of these are unknown, stop anatomical interpretation and document the uncertainty. The real [AAL vertex-map lesson](../../tutorials/en/04_Vertex_Maps_and_Boundaries.md) and [T-map lesson](../../tutorials/en/05_Volume_to_Surface_Mapping.md) show exact-file examples with their limits.
