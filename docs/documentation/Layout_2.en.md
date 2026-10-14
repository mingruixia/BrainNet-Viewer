# Layout 2: eight split views or six complete views

Choose Layout 2, labeled **Overview (6 / 8 Views)**, and Render Scene as usual. Modern rendering automatically uses:

- **Eight views** when triangles form two nonempty, vertex-disjoint X-coordinate groups. If local medial crossings cause those groups to share vertices, exactly two disconnected components may also qualify when each has at least 95% of its referenced vertices on an opposite X side. Qualified components remain intact rather than being cut at X=0.
- **Six complete-data views** when no safe partition is available. This includes node/network-only and ROI-only scenes, single-sided surfaces and connected surfaces crossing the partition. All loaded render geometry is repeated in each pane; “complete” does not mean missing anatomy has been reconstructed.

Six views use a 3-column, 2-row grid: azimuth/elevation `[-90,0]`, `[0,90]`, `[180,0]` above `[90,0]`, `[0,-90]`, `[0,0]`. Panes have equal area, shared fitted camera distance/angle and nonoverlapping axes. No X-half/L/R pane badges appear in this mode, including anatomically confirmed Scenes: these are complete-data panes, not separate hemispheres.

The partition check is independent of vertex and face ordering. Shifted, differently oriented or connected meshes may use the six-view layout. The check decides whether the mesh can be split safely; it does not identify anatomical hemispheres, register data or segment arbitrary geometry. Layouts 1 and 3–5 are unchanged.

The Scene still saves Layout 2. Camera states may contain six or eight views. App/CLI replay fits a new camera and emits `BNV:Render:Layout2CameraReset` if an older saved Layout 2 camera has the other count; the render record reports `reset-layout2-view-count`. It never copies an eight-pane camera onto six panes. Invalid cameras remain errors; direct `restoreCamera` remains strict unless `AllowLayout2Fallback=true` is explicitly requested. Rendering does not overwrite the saved Scene file.

Render/export metadata includes `layout_policy.mode` and `layout_policy.reason`. Figure export and movie cloning use the resolved number of views.
