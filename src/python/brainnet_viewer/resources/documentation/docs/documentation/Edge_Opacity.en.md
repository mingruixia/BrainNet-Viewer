# Edge opacity

[中文](Edge_Opacity.zh-CN.md) · [Colors](Edge_Colors.en.md)

Under **Edges > Opacity**, Uniform uses Value. Mapped uses **Opacity Values** (Signed/Absolute) independently of selection, size and color signs. Set two output opacity bounds with `0 <= low <= high <= 1`; these are not input-weight limits. Zero means transparent, one opaque. Apply/Revert remain global.

Mapped linearly maps selected, sign-adjusted weights from their minimum/maximum to the output range, then clamps rounding drift. Constant weights use the upper opacity, avoiding the legacy divide-by-zero result. Equal output bounds give constant opacity. Tiny nonzero input ranges are mapped, not collapsed using an epsilon cutoff. Nonfinite/complex weights and overflowing ranges are rejected. Alpha zero does not deselect edges or change Connected semantics. Actual appearance still depends on lighting, overlapping geometry and the graphics backend.

EC `opacity=1/2`, `opacity_abs=0/1`, `opacity_same`, `opacity_min/max` round-trip; missing sign/range use legacy Absolute/[0.1,0.9] defaults. Invalid codes and empty/reversed/out-of-range bounds are rejected. Settings **1.9.0** adds `edge.opacity_value_mode`; older 1.0–1.8 settings default to Absolute. Previously ignored Signed EC intent requires reimporting the original EC. Scene records a review warning and only rebinds a valid old camera signature. Scene/preset envelope versions are unchanged.

Related controls include [hemisphere filtering](Edge_Hemisphere.en.md) and [sparsity selection](Edge_Sparsity.en.md). Opacity changes appearance, not membership in the selected edge set.
