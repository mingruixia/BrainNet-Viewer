# Clear Figure

Use **Clear Figure** in the Scene toolbar to close the embedded, pop-out and
compatibility render views. The startup panel returns. Input files, loaded data,
applied visualization settings and export preferences remain available; no file
on disk is removed or overwritten. Geometry caches are retained for fast replay.

The latest modern main-renderer camera is retained as Scene session state.
**Render Scene** restores the retained configuration/camera and makes figure export
available again. A pop-out-only camera edit is not merged into the main view.
Saving Scene after clearing retains the main camera for later replay.

Clear Figure also closes inspection and idle animation-export windows, and disables
render-dependent interactions/export until a new render. An active animation export
must finish or be cancelled first; Clear Figure reports this without clearing anything.
Pending edits in the right settings panel survive Clear Figure; Apply is still needed
to commit them. Clear Figure is not Apply, Revert or a settings reset.

- **Reset** in the canvas toolbar resets the camera.
- **Revert** restores the last applied settings in the editor.
- **Restore Defaults...** [replaces display settings after confirmation](Restore_Defaults.en.md), unlike Clear Figure.
- **Clear** beside a Data Sources role removes that input.
- **Clear Figure** removes rendered views only; repeating it is safe.

Programmatic equivalent: `app.clearFigure()`. The toolbar button is enabled when a
render view exists. Clearing an idle/unloaded App does not read inputs or render data.
