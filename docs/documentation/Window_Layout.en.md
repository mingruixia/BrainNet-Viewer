# Window layout and capture checks

development build + development build · Development guidance · 2026-09-19

[中文](Window_Layout.zh-CN.md) · [Migration](Migration.en.md)

The main interface now uses a top-level layout manager to fill the available client area. Responsive columns follow the root panel's available width, not repeated copies of the figure's requested size. Resize or maximize/restore normally; Apply/Revert and pending edits remain in the same workflow.

Resizing does not reset, Fit or otherwise change the scientific camera. A changed aspect ratio can change what fits in view; use Fit explicitly when needed. The canvas keeps its existing normalized multi-view regions and independent resize policy.

The renderer now fixes the resolved initial camera and axis limits after its first draw. Previously, automatic padded limits could change on resize before the first Fit; this was separate from the window-capture mismatch. The new regression covers all five layouts without first clicking Fit.

**Export Figure** under Data Sources still exports the scientific drawing at the configured dimensions. A whole-window screenshot is a different operation: it includes UI and may include an additional native menu strip. Requested window dimensions, available client dimensions and screenshot dimensions are recorded separately in internal validation.

The validation capture helper waits for layout, checks image dimensions against the client area, detects solid black edge strips, and retries at most three times. It fails explicitly if synchronization cannot be established. Images are not cropped, scaled or painted to pass. These checks are development tooling, not a new screenshot menu or a replacement for Export Figure.

Scope: the prior focused check clipping occurred in a different single-display session. This turn's original normal-window probe did not reproduce it on the current dual-display setup. The managed layout removes a fragile manual sizing path, but does not certify every remote-desktop or DPI configuration. If clipping recurs, retain the whole-window image, Scene, window state, display resolution/scaling and resize steps for review. Some narrow-window labels and dark-theme contrasts remain open.

 This is development guidance, not release acceptance.

![Current full-window multi-view layout, light theme](../tutorials/assets/captures/tutorial07-export/07-layout-4-full-window.png)

Internal GS05 validation image with local input paths, not a cleared public tutorial asset. The fixed bottom Apply/Revert controls remain visible; the settings area scrolls independently. In the 960-wide view, some left-column content requires scrolling and labels remain truncated.

focused check fits new renders once using actual geometry and settled pane dimensions, with shared camera distance/angle across montage views. No automatic Fit is applied on resize. Saved camera states remain explicit: older overly zoomed scenes may still need Fit. Full glyph boxes crossing pane boundaries are temporarily hidden, not truncated; visibility is re-evaluated on camera and size changes. This does not solve collisions or certify every DPI/export format. 
