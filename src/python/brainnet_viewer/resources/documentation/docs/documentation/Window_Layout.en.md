# Window layout

[中文](Window_Layout.zh-CN.md) · [Migration](Migration.en.md)

The main interface now uses a top-level layout manager to fill the available client area. Responsive columns follow the root panel's available width, not repeated copies of the figure's requested size. Resize or maximize/restore normally; Apply/Revert and pending edits remain in the same workflow.

Resizing does not reset, Fit or otherwise change the scientific camera. A changed aspect ratio can change what fits in view; use Fit explicitly when needed. The canvas keeps its existing normalized multi-view regions and independent resize policy.

The renderer fixes the initial camera and axis limits after its first draw. Use Fit to frame the current visible geometry or Reset to restore the layout camera.

**Export Figure** under Data Sources exports the scientific drawing at the configured dimensions. A whole-window screenshot instead includes the interface and may include a native menu strip.

If clipping occurs, record the whole-window image, Scene, window state, display resolution/scaling and resize steps.

![Current full-window multi-view layout, light theme](../tutorials/assets/captures/tutorial07-export/07-layout-4-full-window.png)

The fixed bottom Apply/Revert controls remain visible; the settings area scrolls independently. At narrow widths, some content requires scrolling.

 No automatic Fit is applied on resize. Saved camera states remain explicit: older overly zoomed scenes may still need Fit. Full glyph boxes crossing pane boundaries are temporarily hidden, not truncated; visibility is re-evaluated on camera and size changes. This does not solve collisions or certify every DPI/export format.
