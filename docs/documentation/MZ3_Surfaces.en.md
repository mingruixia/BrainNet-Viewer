# MZ3 surfaces

Development guide · development build · 2026-09-06

Select **Surface Mesh → Add** or **Add Files**, choose `.mz3` or `.mz3.gz`, adjust
**Visualization Settings**, then select **Render Scene**. Scene JSON and
`BrainNetRender` use the same reader. Invalid replacement files leave the previous
inputs/data intact. There is no SPM/Surfice/Python runtime dependency; GZip uses
the Java runtime supplied with the tested MATLAB environment.

Supported geometry is little-endian, indexed triangles with both face and vertex
arrays. The first bytes detect raw data versus GZip, even when a compressed file
has only the `.mz3` suffix. Vertex order, coordinates and face winding are retained;
zero-based disk indices become one-based MATLAB indices. Verify actual units and
registration yourself: a format's MNI coordinate convention is not evidence that
a particular file is correctly registered.

Optional vertex RGBA and float32/float64 scalar layers are read and validated,
but **do not automatically override rendering settings**. Scalar NaN means missing
data and is preserved; infinity is rejected. Layers are inferred from remaining
file length and must be whole nonempty vertex arrays. RGBA plus scalars is not
automatically interpreted as a validated atlas. No label rounding or color-table
application occurs.

```matlab
ref = brainnet.core.InputReference("surface", "cortex.mz3");
[surface, info, arrays] = brainnet.io.readMz3Surface(ref, "D:/my-data");
% arrays.RGBA: N-by-4 uint8 (0..255), or empty
% arrays.Scalars: N-by-L double, retaining source precision and NaN
```

The optional arrays remain outside Scene metadata. Metadata record counts, flags,
encoding, scalar precision/layers/missing count and explicit appearance policies.
Input hashes bind the full source file. Private skipped header bytes are opaque:
they are neither executed nor interpreted as transforms or metadata instructions.

| Direct-reader limit | Default |
|---|---:|
| `MaxVertices` | 10,000,000 |
| `MaxFaces` | 20,000,000 |
| `MaxBytes` (input and decoded bytes) | 1,073,741,824 |
| `MaxSkipBytes` | 16,777,216 |
| `MaxScalarLayers` | 256 |

GZip is decoded in bounded chunks to a unique temporary file, with CRC/size checks
and cleanup on success/error. These are input/decoded-size limits, not a guarantee
that peak MATLAB memory stays below MaxBytes. Geometry/array lengths, flags,
finite coordinates and index bounds are checked before use. Extra bytes with no
scalar flag are rejected; with scalars, an additional complete layer is legitimate
because MZ3 contains no separate layer count.

Not supported by this surface entry point: overlay-only files, point clouds,
ambient-occlusion flags, embedded JSON lookup flags, future flags, mixed float32
and float64 flags, or big-endian MZ3. Single-member GZip is the validated scope;
nested/multi-member containers are not advertised. Structural validation is not
a topology, self-intersection, atlas-label or registration quality certificate.

See [Scene workflow](Scene_Workflows.en.md) and the
[format matrix](../compatibility/Surface_Format_Support.md). Development tests
used pinned Surfice format examples, project-created edge-case files and a
FreeSurfer-derived cortex conversion. These fixtures are **not** shipped with
this guide; separate redistribution must retain the relevant Surfice/BSD-2-Clause
and FreeSurfer source notices and licenses.
