# Coordinate and anatomical pane labels

**Show Orientation Labels** controls two pane badges in multi-view layouts (2–5).
They identify the negative/nonpositive and positive X half-space panes, not the
screen edges after camera rotation. Single-view layout has no such badges.
Layout 2's [six complete-data fallback](Layout_2.en.md) also has no half-space badges.

Unconfirmed Scenes now show **X<=0 / X>0**, not anatomical L/R. This applies to
unknown, MNI-named, human, animal, native and custom coordinate spaces alike.
The renderer cannot establish orientation or registration from a name. Existing
partitioning is unchanged: nodes use X sign, mesh triangles use centroid X;
the badges do not promise exact geometric clipping at the midline.

## Explicit anatomical confirmation

After verifying that all displayed inputs share the intended coordinates, the
anatomical midline is X=0, and the positive-X direction is known, seal the Scene's
input hashes and explicitly confirm. Use the Scene/API to record this confirmation; the interface has no confirmation dialog:

```matlab
sealed = app.saveSceneFile("scene-before-orientation.json");
confirmed = brainnet.core.OrientationLabels.confirm(sealed, "right", ...
    MidlineIsXZero=true);
app.setScene(confirmed);
app.saveSceneFile("scene-confirmed.json");
app.renderCurrentScene(Target="embedded");
```

Use `"left"` only when increasing X points anatomically left. This reverses L/R
badges; it does not transform geometry, swap cameras or register data. Never
confirm simply to restore the old appearance. Missing hashes or an unconfirmed
X=0 midline cause an error.

The optional `metadata.orientation_labels` declaration binds version 1.0,
`x_positive`, `midline_is_x_zero` and `input_signature` to all Scene input references
(including hashes) and the coordinate-space declaration. Changed inputs/space,
malformed declarations or missing hashes revert to coordinate badges. Reconfirm
only after checking the new data. Presets do not carry this Scene-specific metadata.
Confirmation is a user assertion, not independent verification of registration.

## Contrast, export and compatibility

Modern badges use black/white text with an opposite-color opaque backing, so an
explicit export-background override cannot erase text/background contrast. Theme
changes do not recolor them. Render/export provenance records the effective label
policy and its reason. This is a pane badge, not a general node-label contrast fix.

The modern Legacy Renderer adapter rejects multi-view anatomical labels when the
declaration is missing/stale or positive X points left: use Modern Batch Renderer
or disable Show Orientation Labels. The original legacy code and external legacy
launch paths are unchanged. Legacy badge styling is not modernized here.

The same orientation checks apply to animal data. Confirm the axes and midline rather than inferring them from the species or template name. Labels do not transform or resample the data. Check their readability in the exported figure.
