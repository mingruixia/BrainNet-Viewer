# Volume display and Adjust for Null

In **Volume / ROI**, use Surface Map, then **Display Values** and **Adjust for Null**.
Apply/Revert remain shared. These controls are disabled for ROI geometry.

| Display Values | Color-axis limits | Adjust for Null enabled |
|---|---|---|
| Positive & Negative | Symmetric `[-M, M]`, where `M` is the larger absolute endpoint | Intermediate null band uses Null Color |
| Positive Only | Positive minimum → positive maximum | First palette bin uses Null Color |
| Negative Only | Negative minimum → negative maximum | Last palette bin uses Null Color |

These are display ranges, **not sign-based data filters**. MATLAB clamps values outside
the range to the palette endpoints. In one-sided modes, equality at the null-side
endpoint is null-colored; nearby values in that same discrete bin are also null-colored.
With adjustment off, all finite values use palette colors, including the former null
band and opposite-sign values clamped at the endpoints. Source/mapped values are unchanged.

Both uses one selected 256-color diverging palette: lower 128 rows for negative and upper
128 rows for positive values. The symmetric axis puts zero at their midpoint, including
when signed extrema differ. With adjustment on, the configured null band uses Null Color;
with adjustment off, colors pass continuously through zero. One-sided modes resample the
corresponding palette half to 256 rows. Null Color
is disabled while adjustment is off. Out-of-range vertices are not hidden or transparent.

Auto defaults: Both starts from finite data extrema, then expands the smaller-magnitude
side to make the displayed range symmetric. This can make that sign's contrast paler.
Positive uses zero to the positive
maximum (fallback 1); Negative uses the negative minimum (fallback -1) to zero.
Explicit range endpoints contribute to the same calculation. Degenerate limits expand
the upper endpoint by 1. Review constant-valued data manually. Manual bounds persist
when a volume file is replaced; the Scene summary identifies them. In the Volume panel,
**Auto Ranges** sets both pending fields to Auto; click the shared **Apply** to commit
and render. Revert discards pending edits.

Settings **1.15** adds `volume.display_mode` and `volume.adjust_null`. Older scenes
default to Both/on, preserving their modern mapping; valid camera bindings are migrated,
stale bindings are not. EC `vol.display` 1/2/3 maps to Both/Positive/Negative and
`vol.adjustCM` 0/1 to off/on. Earlier development EC imports lost this intent: reimport
the original EC. Off/0 is retained as the development compatibility sentinel.

Settings **1.22** uses one saved colormap; older two-palette Scenes are migrated to a
composite custom map. This is **not legacy pixel equivalence**: the old 1000-bin map,
orientation, interpolation and auto ranges can differ. Surface Map P-value conversion
is now available for supported NIfTI statistic metadata; it does not correct for multiple comparisons.

