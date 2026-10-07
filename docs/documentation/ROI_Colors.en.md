# Custom ROI colors

In **Volume / ROI**, choose **Custom** under ROI Color Mode. Use **Load ROI Colors...**
or edit the text box. Shared **Apply** commits the table and renders; **Revert** restores the
last applied table. Loading alone does not change the rendered scene.

Each TXT/CSV row is `ROI_ID R G B`, separated by spaces or commas, with no header.
IDs must be unique positive integers; RGB must be finite and within 0–1 (not 0–255).
At most 10,000 rows and a 2 MB input file are accepted. Example:

```text
8 1 0 0
42 0 0 1
```

Copy the two rows above into a `.txt` file if you want to try **Load ROI Colors...**. Colors attach to IDs,
not row order or selection position. Extra IDs are allowed. Every selected ID
present in the volume must have a color; missing colors stop preparation with an
error, **never an index-color fallback**. Empty selections/volumes render no ROIs.
Uniform and Label Index modes keep their existing behavior.

For an atlas, IDs are voxel labels. For statistical ROIs, IDs are the consecutive
cluster IDs produced after filtering. Threshold/connectivity changes can alter IDs;
review colors after such changes. A table is not anatomical registration and is not
bound to a specific atlas/file. See [statistical ROI rules](Statistical_ROI.en.md).

## Saving and migration

Settings **1.16** stores the table in `roi.custom_colors`, embedded in Scene/Preset
JSON. Tables affect the preparation cache key. Older scenes gain an empty table;
their previous Custom→Index fallback is retired. Supply a table or explicitly
choose Label Index. A migration note is recorded; valid camera bindings migrate
while stale bindings remain stale.

Legacy EC colors were positional (`vol.roi.color(i,:)` corresponds to `draw(i)`).
Import uses applied `draw`, or `drawt` when draw is empty; absent/invalid IDs are
rejected for displayed ROI configurations with colors. Unapplied `colort` edits
are not imported. EC export requires Draw All off and a nonempty explicit selection;
rows are reordered to that selection. Custom ROI rendering requires Modern Batch,
not the legacy GUI adapter. The current version supports [boundary and small-ROI handling](ROI_Geometry.en.md), without claiming legacy mesh equivalence.

