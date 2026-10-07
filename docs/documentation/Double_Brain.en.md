# Double Brain

development build · Development build · 21 September 2026

Load a surface, optionally with a node file and edge matrix. Set Layout to **Single View** and direction to **Left (Sagittal)**, **Superior (Axial)** or **Anterior (Coronal)**. Under **Surface**, enable **Double Brain**, then use the global **Apply** to commit and render. Disable the checkbox to return to one brain. Revert restores the last applied setting; Restore Defaults turns this option off.

## Input order matters

This restores the original two-brain arrangement, not two copies of the network. For N node rows, rows 1 through floor(N/2) belong to brain 1; all remaining rows belong to brain 2. Provide the two groups consecutively, in the same source coordinate system. Edge matrix rows/columns follow this complete original node order, including cross-brain connections. Odd N preserves the historical floor split. The App does not infer subjects, hemispheres, or node correspondence.

Both brains use the same loaded surface, with uniform color or independent [Vertex RGB](Vertex_RGB.en.md) tables added in focused check. The second surface is a display copy. Left view rotates it 180 degrees about Z and separates it along Y; Superior/Anterior translate it along positive/negative X. The surface-bound-based gap is 10%, matching the original formulas; unusually large node glyphs can require smaller sizes. The two surfaces share one axes and camera, fitted to their combined bounds.

Only display coordinates move. Source files, coordinates, IDs, filtering, node values, edge weights and source-space length colors remain unchanged. Labels follow displayed nodes. Clicking a second-brain surface/node converts the hit back to source coordinates for Inspect; this does not establish atlas registration. Cross-brain connections depict graph relationships, not physical tracts between displaced brains.

## Persistence and limits

- Settings 1.17 adds `surface.double_brain` (default false). Older Scene/preset files migrate with it off; an old EC `msh.doublebrain` value of 0/1 is preserved when imported/exported.
- App Apply, preset compatibility and render entry points reject unsupported combinations. Use a surface with optional nodes/edges, uniform or vertex RGB color, Single View and one of the three directions above. No volume/ROI/scalar-map input, node-only scene, montage or arbitrary camera-direction preset is supported for initial Double Brain rendering. Subsequent camera interactions/animation remain available.
- Surface boundary masks override the same vertices on both surfaces; focused check preserves independent RGB elsewhere. This is not general multi-subject scene composition.
- Scene/preset JSON, figure metadata, camera replay and movie cloning preserve the option. Toggling or changing direction invalidates display geometry as needed, without reinterpreting original coordinates.

Focused checks and limitations are recorded in the focused check report. Full regression, manual visual acceptance and all-platform certification remain pending.
