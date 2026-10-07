# M13 · Surface formats and mesh tools

[中文](../zh-CN/M13_Surface_Tools.md) · [Manual index](index.md) · [Format matrix](../../compatibility/Surface_Format_Support.md)

A successfully read mesh is **not** proof of MNI registration, matching units, compatible handedness, or permission to redistribute it. The modern readers preserve raw geometry rather than silently applying a dataset-specific transform.

## Load and review a surface

In **Data Sources → Surface Mesh**, select a supported mesh; then **Validate and Load**, configure the display, and **Apply** to render. The same independent readers serve the desktop, Scene JSON and `BrainNetRender`. Surface support includes `.nv`, FreeSurfer `.pial`, BrainVISA `.mesh`, BYU/MOVIE.BYU `.g`, MNI/BIC `.obj`, MZ3 `.mz3/.mz3.gz`, and GIfTI `.gii/.gii.gz`, within each reader's restrictions. `.obj` means the MNI/BIC polygon format here, **not** generic Wavefront OBJ. `.mesh` does not imply Medit format. `.pial` is the advertised FreeSurfer desktop suffix; do not assume arbitrary FreeSurfer suffixes or compressed `.pial.gz` work. See the [FreeSurfer](../../documentation/FreeSurfer_Surfaces.en.md), [BrainVISA](../../documentation/BrainVISA_Surfaces.en.md), [BYU](../../documentation/BYU_Surfaces.en.md), [MNI/BIC](../../documentation/MNI_BIC_Surfaces.en.md) and [MZ3](../../documentation/MZ3_Surfaces.en.md) guides for exact encodings and rejection rules.

Coordinates and face winding are kept as returned by each reader; disk indices become one-based internally. BrainVISA `.mesh` **does not** receive the original BrainNet's implicit XYZ inversion. FreeSurfer surface RAS is not automatically scanner RAS/MNI. GIfTI transform metadata is recorded, not automatically applied by the mesh utilities. MZ3 embedded RGBA/scalars are validated but not automatically promoted to display settings or Surface Map. Verify space and geometry alignment before combining a mesh with nodes, volume, atlases or other surfaces. A single unsplittable mesh should use applicable full-surface layouts; two-hemisphere layouts cannot be assumed from its filename.

## Tools that write new data

| Tool in Tools | Inputs and operation | Output / caution |
|---|---|---|
| **Merge Surfaces** | Automatically review 2–64 meshes, order, bounds, counts and SHA-256; optional space, units and note, no verification checkbox. | Concatenates coordinates/faces into a new ASCII `.nv`; does not register, weld, smooth, repair or transfer color/scalar attributes. |
| **Convert Surface to NV** | Review one supported mesh and optional space/unit declarations. | New `.nv` preserving reader-returned geometry; no implicit legacy `.mesh` coordinate inversion or attribute transfer. |
| **Subdivide Surface to NV** | Review one mesh; choose 1–3 linear midpoint levels (4× faces per level). | New denser `.nv`; no smoothing, curvature preservation or automatic node/map correspondence. |
| **Generate Nodes from Atlas** | Review a discrete integer NIfTI label atlas, selected region IDs, affine and declared space/units. | New `.node`; each region uses its unweighted voxel-centre centroid, which need not lie within a concave/disconnected region. No registration or name lookup. |

Each tool has a review step, checks source/dependency fingerprints again before publication, writes a **new** destination without replacing an existing one, and leaves the active Scene unchanged. Mesh utilities use default combined limits of five million vertices and ten million triangles; read/allocation may still require substantial RAM. The `.nv`/`.node` output includes a `#` JSON provenance comment, potentially with absolute source paths. Do not publish it without inspecting privacy and licensing. Declarations in comments do **not** assign a Scene coordinate space or perform transforms. Load the new file explicitly through Data Sources; for a portable Scene, place it within the configured data root or use an appropriate root. See [merge](../../documentation/Surface_Merging.en.md), [convert](../../documentation/Surface_Conversion.en.md), [subdivide](../../documentation/Surface_Subdivision.en.md), and [atlas nodes](../../documentation/Atlas_Nodes.en.md) for exact review fields, formats and limits.

These geometry operations are not a scientifically validated surface-registration pipeline. Verify anatomy and resource permissions for each dataset before using or distributing derived files.

## FreeSurfer hemisphere workflow

Use `lh.pial` and `rh.pial` from the same subject or template and the same surface reconstruction. Merge in left-then-right order, retaining the stored surface coordinates. Load the new NV file explicitly. A separable pair enables lateral/medial and eight-view layouts; one hemisphere alone does not invent its counterpart. Local medial crossings of X=0 are accepted only under the conservative disconnected-component rule described in [Layout](M04_Layout_Camera.md).

For a per-vertex Surface Map, concatenate values in exactly the same left-then-right order and supply one value for every original merged vertex. Do not reorder vertices or subdivide the mesh after preparing the values. `.annot` is not a direct Surface Map input: first decode it externally into per-vertex parcel IDs using the matching hemisphere's annotation/label table. Map region statistics to those IDs before concatenation; annotation color codes are not themselves region statistics. This version does not automatically decode or transfer annotations. Node coordinates must use the same declared space as the mesh. Stored FreeSurfer surface coordinates are not automatically MNI coordinates; do not apply MNI NIfTI mapping or AAL/Brodmann Inspect without a verified alignment. A complete illustrated exercise will be incorporated during the pre-release manual revision.
