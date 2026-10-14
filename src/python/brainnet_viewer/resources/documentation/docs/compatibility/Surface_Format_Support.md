# Modern surface input matrix / 现代表面输入矩阵

This table describes the MATLAB reader and its App, Scene and command-line entry points. Consult each format guide for encoding and coordinate requirements.

| Format | Modern MATLAB reader | App / Scene / CLI | Requirements and limitations |
|---|---|---|---|
| BrainNet `.nv` | Supported | Supported | Existing ASCII triangle contract |
| GIfTI `.gii`, `.gii.gz` | Supported | Supported | Existing point-set/triangle array contract |
| FreeSurfer `.pial` | Supported | Supported | Triangle, old/new quad; geometry only; no coordinate transform |
| FreeSurfer `.white/.inflated/.sphere` etc. | Not supported through this entry point | Not routed | A similar binary encoding does not establish UI support |
| FreeSurfer `.pial.gz`, ASCII, patch | Not supported | Not routed | Explicit future scope |
| BrainVISA `.mesh` | Supported | Supported | ASCII / binary BE / binary LE; one time step, VOID, triangles; no legacy XYZ inversion or MINF transform |
| BrainVISA time series / lines / quads / textures, `.mesh.gz`, Medit `.mesh` | Not supported | Explicitly rejected / not routed | No silent frame selection or polygon conversion |
| MOVIE.BYU `.g` | Supported | Supported | ASCII triangles; all parts with ordered/disjoint/full polygon ranges; stored coordinates and winding retained |
| BYU quads/n-gons, BRL-CAD `.g`, `.g.gz`, `.byu`, companion `.d/.s/.t` | Not supported | Rejected / not routed / not auto-loaded | No silent triangulation, part selection, displacement or texture application |
| MNI/BIC `.obj` | Supported | Supported | Single uncompressed triangle object, ASCII / binary BE / LE; both triangle-size table encodings; geometry only, source appearance not applied |
| Wavefront OBJ, compressed MNI topology, multiple objects, non-triangles, `.obj.gz` | Not supported | Rejected / not routed | No silent first-object selection, external model loading or triangulation |
| MZ3 `.mz3`, `.mz3.gz` | Supported | Supported | Raw/GZip little-endian triangles; optional RGBA and float32/float64 multi-layer scalars decoded but not applied; NaN scalars retained |
| MZ3 overlay-only, AO/JSON lookup/future flags, point clouds, big-endian | Not supported | Explicitly rejected | No automatic atlas interpretation or unsupported flag ignoring |

中文：`.pial` 支持三种二进制几何编码，保留原始坐标，不应用尾部标签中的变换。其他格式及扩展名的支持范围见表格和相应专题指南。
