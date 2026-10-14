# Window layout

[中文](Window_Layout.zh-CN.md) · [Migration](Migration.en.md)

The main window adjusts its columns to the available width. Resize, maximize or restore the window as needed; these actions retain pending settings and the Apply/Revert controls.

Resizing does not reset, Fit or otherwise change the scientific camera. A changed aspect ratio can change what fits in view; use Fit explicitly when needed. The canvas keeps its existing normalized multi-view regions and independent resize policy.

The renderer fixes the initial camera and axis limits after its first draw. Use Fit to frame the current visible geometry or Reset to restore the layout camera.

**Export Figure** under Data Sources exports the scientific drawing at the configured dimensions. A whole-window screenshot instead includes the interface and may include a native menu strip.

If clipping occurs, record the whole-window image, Scene, window state, display resolution/scaling and resize steps.

![Current full-window multi-view layout, light theme](../tutorials/assets/captures/tutorial07-export/07-layout-4-full-window.png)

The fixed bottom Apply/Revert controls remain visible; the settings area scrolls independently. At narrow widths, some content requires scrolling.

Resizing preserves the saved camera. Use **Fit** if an older Scene opens too closely zoomed. Labels that cross a pane boundary are temporarily hidden and reappear when the camera or pane size permits. This prevents clipped text but does not prevent labels from overlapping each other.
