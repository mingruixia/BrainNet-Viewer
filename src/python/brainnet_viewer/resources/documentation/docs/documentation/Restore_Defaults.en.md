# Restore Display Defaults

The fixed footer in the right-hand settings panel contains **Restore Defaults...**
above the single **Revert / Apply** pair. It affects all display categories, not
just the expanded category. A confirmation explains the scope; **Cancel** is the
default and close/escape choice. Cancel leaves the current figure and pending edits
untouched.

After confirmation, layout, global appearance, surfaces, nodes, edges, volume/ROI
and fiber settings return to the versioned defaults. Titles and colorbar annotations
also reset. Applied custom palettes, masks and per-element settings are replaced,
and uncommitted editor values are discarded. **Revert does not undo this confirmed
reset**; save a Scene/preset beforehand if you need to recover the previous style.

Inputs, coordinate/orientation declarations, inspection configuration, Scene identity,
export preferences (including image width/height/DPI) and UI theme are retained.
No file on disk changes. Existing render views stay visible, without returning to
the welcome page. A status message asks you to select **Apply** or **Render Scene**
to redraw with defaults; the saved camera resets for that next render. The retained
canvas is a preview, and export is disabled until redrawn. No automatic render
or export occurs. Active animation export must finish or be cancelled first.

This is different from **Revert** (discard only pending edits), canvas **Reset**
(camera only), and **Clear Figure** (keep applied styling and main camera for replay).

Programmatic use requires explicit confirmation:

```matlab
report = app.resetVisualizationSettings(Confirmed=true);
```

Calling without confirmation returns `status = 'cancelled'` without mutations.
For safety, invoking the UI callback on a hidden App does not auto-confirm.
