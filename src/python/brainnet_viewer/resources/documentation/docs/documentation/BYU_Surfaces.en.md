# MOVIE.BYU surfaces

Use **Surface Mesh → Add** or **Add Files** to select an ASCII MOVIE.BYU `.g` file, adjust **Visualization Settings**, then select **Render Scene**. `.g` also works through Scene JSON and `BrainNetRender`; Python/SPM/VTK are not runtime requirements.

The modern reader supports **triangular geometry**, including multiple parts. The part ranges must be ordered, nonempty and disjoint, covering polygons 1 through the declared last polygon. All parts are kept in file order in one surface; part boundaries are recorded in metadata, not exposed as independently styled layers. Stored vertex order, coordinates and triangle winding are retained. The negative last index of each triangle is a terminator, not a coordinate reflection.

The reader checks counts/resource limits, part ranges, finite coordinates, index bounds, every triangle terminator, incomplete arrays and unexpected trailing content. Selecting an invalid new file leaves the previous inputs/data intact. It rejects quadrilaterals, arbitrary polygons and mismatched connectivity counts instead of silently triangulating or taking only one part.

No displacement `.d`, scalar `.s` or texture `.t` companion file is loaded automatically. No registration or unit conversion is performed: verify alignment and units before combining BYU geometry with nodes, volumes or atlases. The `.g` extension is not a universal geometry detector: BRL-CAD binary `.g`, compressed `.g.gz` and `.byu` filename routing are not enabled in this step. Fixed-width positive fields concatenated without numeric separation are not advertised; whitespace-separated numbers and adjacent signed scientific coordinates are supported.

```matlab
ref = brainnet.core.InputReference("surface", "cortex.g");
[surface, info] = brainnet.io.readByuSurface(ref, "D:/my-data");
info.part_polygon_ranges
```

Limits default to 10 million vertices, 20 million triangles and 100,000 parts, and can be reduced with `MaxVertices`, `MaxFaces`, `MaxParts`. Header values must be positive signed 32-bit integers. This is structural validation, not a guarantee of manifold topology, absence of self-intersections, or correct registration.

Unlike the old single-part triangle loader, this reader validates the complete part table. It does not change the legacy implementation. See [Scene workflow](Scene_Workflows.en.md) and the [format matrix](../compatibility/Surface_Format_Support.md). Development tests used a project-created multipart tetrahedron, a FreeSurfer-derived cortex conversion and a third-party quadrilateral cube as a rejection case. None is automatically an application resource; distributing the latter two requires separate FreeSurfer attribution and verification of the cube's upstream LGPL version/notice.
