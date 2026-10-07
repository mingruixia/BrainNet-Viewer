# MNI/BIC OBJ surfaces

Development guide · development build · 2026-09-06

Choose **Surface Mesh → Add** or **Add Files**, select an MNI/BIC `.obj`, adjust
**Visualization Settings**, and select **Render Scene**. The same reader is used
by Scene JSON and `BrainNetRender`. SPM, BICPL, VTK and Python are not runtime
dependencies. Invalid new selections leave the previous inputs/data intact.

Supported: a single uncompressed triangle polygon object, ASCII `P` or binary
`p`; cumulative triangle ends `3,6,9,...` and per-polygon sizes `3,3,3,...`.
Binary int32/float32 byte order is tested in both directions. Auto mode accepts
only one completely valid interpretation; ambiguous/invalid data are rejected.
No universal endianness marker exists in this format.

The file suffix does **not** mean Wavefront OBJ, and “MNI” does **not** establish
MNI standard-space registration. Coordinates, vertex order and winding are
preserved without reflection, scaling or registration. ASCII coordinates retain
double parsing precision; binary coordinates retain their float32 values.
Check alignment and units before combining the surface with other data.

Overall, per-face and per-vertex RGBA tables are counted and validated correctly.
ASCII colors are RGBA floats in [0,1]; binary colors are four ABGR bytes, not
four floats. Source material, colors and normals **do not override display
settings**. Small metadata include material values, color mode/count, appearance
hashes and overall RGBA when applicable, not full color/normal arrays. Normals
must be finite but need not be exactly unit length; rendering computes normals.

Not supported here: Wavefront OBJ, compressed topology, quads/n-gons, Q quadmesh,
lines/markers/text/pixels/model references, multiple objects or `.obj.gz` routing.
There is no silent triangulation or first-object selection. ASCII trailing
whitespace is allowed; binary arrays must end exactly at EOF.

```matlab
ref = brainnet.core.InputReference("surface", "cortex.obj");
[surface, info] = brainnet.io.readMniObjSurface(ref, "D:/my-data");
% Only for a file whose byte order is independently known:
[surface, info] = brainnet.io.readMniObjSurface(ref, "D:/my-data", ByteOrder="big");
```

`ByteOrder` (`auto`/`little`/`big`) is a direct-reader option, not a Scene setting;
App/Scene/CLI use auto. Defaults: `MaxVertices=10000000`, `MaxFaces=20000000`.
Counts, minimum file lengths, finite arrays, triangle lengths, index bounds,
hashes and trailing content are checked. This does not establish manifold
topology, absence of self-intersections, valid registration or unit normals.

See the [format matrix](../compatibility/Surface_Format_Support.md) and
[Scene workflow](Scene_Workflows.en.md). Development checks used project-generated
small polygon objects and a cortex conversion from FreeSurfer fsaverage; the
converted file is **not** a native MNI/BIC specimen and is not included here.
Any separate redistribution of that test file must retain the FreeSurfer source
attribution and license.
