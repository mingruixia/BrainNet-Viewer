# Node colors: column 4 and threshold colors

[中文](Node_Colors.zh-CN.md)

## Scientific meaning

A node file uses columns 1–3 for coordinates, column 4 for color values/modules, column 5 for size values and column 6 for labels. **Mapped, Threshold, Modules and Custom node colors use column 4; changing only column 5 must not change color.** Size behavior is outside this repair.

- Uniform uses the single Color button.
- Mapped samples the selected colormap at 256 RGB rows and maps column 4 to it. Empty limits use the full input column's minimum/maximum, not only visible nodes. Fixed limits clamp values outside the range. Constant values with automatic limits use the first color. This is the modern quantized mapping, colors may differ from those produced by earlier palette indexing.
- Threshold uses exactly two RGB colors: **Low (<=)** for column 4 less than or equal to Color Threshold; **High (>)** for values strictly greater. Palette and color limits do not affect this mode.
- Modules uses the existing sorted-unique-category palette mapping; custom module palettes retain their prior behavior.

## Desktop workflow

1. Load node data, then open **Nodes >** in Visualization Settings.
2. Choose **Color Mode**. For Mapped, set the colormap and optional low/high limits. For Threshold, set **Color Threshold**, **Low (<=)** and **High (>)**.
3. Commit and render with the single bottom **Apply**. The two colors stay pending until Apply. **Revert** restores the last applied values.
4. Save Scene or Save Preset. Both retain threshold colors; Scene also retains input references and valid session state.

![Current Threshold node-color controls](../tutorials/assets/captures/topic-guides/node-color-threshold-panel.png)

The focused panel capture shows the current controls; it does not assess the appearance of a rendered network.

## Old EC settings

For `EC.nod.color=4`, import requires a finite RGB `EC.nod.CM` containing at least 64 rows: **row 1 is high**, **row 64 is low**. Short/missing tables are rejected rather than guessed. The threshold itself comes from `EC.nod.color_threshold`. For mapped mode (2), an available numeric CM is preserved; no MATLAB expression is evaluated. Uniform mode uses CM row 1.

`color_map_type=1` means automatic limits even if stale low/high fields are present. Type 2 requires both bounds. If the type flag is absent, paired bounds preserve the earlier import convention. Export to EC writes the two threshold endpoints back to rows 1/64 and writes the range-mode flag. Review the import report for other legacy settings.

## Earlier development Scenes and presets

Settings 1.0–1.2 upgrade to 1.3. When the new colors are absent, Low starts from the saved uniform node color and High from the last saved colormap color. This is a documented migration choice, not recovery of an old two-color intent: the earlier modern Threshold mode had a continuous high group and read the wrong column. **Review old mapped and threshold figures after upgrading; colors intentionally change.**

Old Scene metadata records a node-color upgrade notice. Valid saved cameras are rebound only after the original canonical settings/input signature is checked; stale cameras remain stale. Presets upgrade settings without importing a camera. These color fields were introduced in Settings 1.3 and are retained in current Settings 1.5 files; earlier builds are not promised to read them.
