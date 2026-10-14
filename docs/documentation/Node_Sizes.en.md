# Node sizes: Raw, Mapped and threshold radii

[中文](Node_Sizes.zh-CN.md) · [Node colors](Node_Colors.en.md)

## Meaning and calculation order

**Size Source → size processing → Scale → radius**. A radius is in the same coordinate units as the loaded nodes; the software does not infer millimetres or encode sphere volume. Doubling the radius increases sphere volume eightfold.

Size Source **Node Value** uses .node column 5. **Module** uses column 4 as a modern extension; it does not mean the legacy Raw option. Module-source sizing cannot be exported to EC for non-uniform modes and requires the modern renderer. Color settings are independent.

| Size Mode | Radius before Scale |
|---|---|
| Uniform | Base Size |
| Mapped | Legacy normalization of all source values: shift negatives, raise the minimum, repeatedly log-compress a max/min ratio above 10, then linearly map to 2–7; constant input gives 4 |
| Raw | The source value, without normalization |
| Threshold / Mapped | Normalize first; replace radii strictly below Size Threshold with 1 |
| Threshold / Raw | Use original source values; replace radii strictly below Size Threshold with 1 |

**Scale multiplies every mode exactly once**, including Uniform. Equality with the threshold is retained; the threshold is compared before Scale. Threshold is not a two-fixed-size mode. Example: Raw values `[1,2,3]`, threshold `2`, Scale `3` produce radii `[3,6,9]`; Mapped values `[1,2,3]`, threshold `4.5`, Scale `2` produce `[2,9,14]`.

Normalization uses the complete input, before visibility filtering or hemisphere splitting. Negative/overflowed final radii are rejected, not silently converted to absolute values. A final radius of zero omits that node's sphere and label; the input node and its edges are retained. Raw-threshold negative values may become valid if the threshold rule replaces them with 1. Degenerate negative-radius legacy rendering is intentionally not reproduced.

## Desktop workflow

1. Load nodes. Open **Visualization Settings → Nodes >**, then scroll to **Size**.
2. Choose **Size Mode** and **Size Source**. Uniform enables Base Size. Scale remains active for all modes.
3. For Threshold, choose **Mapped** or **Raw** beside Size Threshold and enter the threshold. Both controls are inactive in the other modes; Base Size does not affect Threshold.
4. Use the single bottom **Apply** to commit and render. **Revert** discards uncommitted settings. Scene/preset saving stores the applied settings.

![Current Threshold node-size controls](../tutorials/assets/captures/topic-guides/node-size-threshold-panel.png)

The screenshot shows the size controls. Review the rendered radii after applying the settings.

## EC and older development files

| EC setting | Modern setting |
|---|---|
| nod.size=1 | Uniform |
| nod.size=2, size_value=1 | Mapped, Node Value |
| nod.size=2, size_value=2 | Raw, Node Value |
| nod.size=3, size_value=1 | Threshold with Mapped, Node Value |
| nod.size=3, size_value=2 | Threshold with Raw, Node Value |
| nod.size_size / size_ratio / size_threshold | Base Size / Scale / Size Threshold |

The implementation follows the frozen legacy renderer's processing order, not the old dialog's slider range. Uniform ignores the inactive size_value choice. A missing EC size_value retains the existing default Mapped interpretation; unknown enum codes fail validation. The source `.node` file remains unchanged.

Settings 1.0–1.3 upgrade to 1.4. A missing size_threshold_basis starts as Mapped. **Old Uniform settings with Scale other than 1 and old Threshold settings can render differently after correction. Review the output.** Existing saved module-source sizing remains module-source; an old mistaken EC import cannot be distinguished from deliberate module sizing. Reimport the untouched original EC to recover Raw intent. Do not automatically convert every module setting to Raw.

Old Scene metadata records node_size_upgrade. Only a matching original canonical input/settings signature permits camera rebinding; stale cameras stay stale. Presets carry settings, not cameras. Scene v0.1 and preset v1.0 envelope versions are unchanged; earlier builds are not promised to read Settings 1.4.
