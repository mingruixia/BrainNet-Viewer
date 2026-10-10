# Merge surfaces

For one input, use [Convert Surface to NV](Surface_Conversion.en.md). Merge requires 2–64 inputs; space, units and note are optional metadata.

## Desktop workflow

1. Open **Tools → Merge Surfaces...**. The separate, non-modal window does not change the active Scene.
2. **Add Files...** selects 2–64 surfaces. **Remove / Move Up / Move Down** control membership and order. Duplicate canonical paths are rejected.
3. Inputs are reviewed automatically after adding, removing or reordering files. Inspect full paths, vertex/triangle counts, resulting one-based index ranges, coordinate bounds and SHA-256. Review writes no output; fewer than two inputs cannot be saved.
4. Optionally enter **Space**, **Units**, and **Note**. Blank space/units are recorded as `unknown`; no verification checkbox is required. No registration or unit conversion is applied: anatomical alignment remains the user's responsibility.
5. Select **Save New .nv...** and choose a new filename. Existing files cannot be overwritten, even if the system save dialog asks about replacement. Source files and GIfTI external arrays are rechecked before publication.
6. To display the result, choose it through **Surface Mesh**, configure the visualization and **Render Scene**. The file must be inside the app's configured data root, as for all portable Scene inputs. Save under that root, or launch an app with an appropriate root (`brainnet.app.launch(dataRoot)`). Saving does not automatically replace data/settings or change the root.

Confirming or cancelling Open/Save returns focus to the Merge window, not the MATLAB desktop. The following screenshot predates the simplified controls; counts and bounds are unchanged.

![Input review in the light theme](../tutorials/assets/captures/tutorial11-merge-boundary/11-merge-review.png)

This screenshot deliberately mixes a FreeSurfer surface and a template for review only. It is **not a registered pair and is not saved**; do not use it as a scientific merge example.

## Formats and scientific boundaries

Inputs reuse the independent `.nv`, `.pial`, `.mesh`, BYU `.g`, MNI/BIC `.obj`, `.mz3/.mz3.gz` and `.gii/.gii.gz` readers with their existing restrictions. Output is ASCII `.nv` only.

Raw coordinates are concatenated in list order; face indices receive preceding vertex counts as offsets. Coincident vertices remain separate and winding is retained. GIfTI matrices and available native metadata are recorded, **not applied as transforms**. There is no registration, rescaling, mirroring, welding, smoothing, intersection repair, unused-vertex removal or color/scalar/material/normal/semantic-label transfer.

The second `#` comment line embeds versioned JSON provenance: source paths/hashes, GIfTI external-array hashes, native metadata, component ranges/bounds and your space/units/evidence declaration. Absolute paths may reveal local directory names; inspect before sharing. Normal `.nv` loading ignores comments: this record **does not automatically assign Scene coordinate space**. Merging does not change resource redistribution rights.

Coordinates use 17 significant digits and undergo exact double-array read-back checks before publication. Output is staged beside the destination and published with a no-replace move; handled failures clean temporary files. Changed inputs require review again. This is not a filesystem snapshot and cannot prevent changes after the final hash check.

Default combined limits: 5 million vertices and 10 million faces. Limits are checked after each reader returns, before concatenation, not before each reader's allocation. Arrays and a read-back copy require additional RAM. No GPU acceleration is claimed for this file-oriented utility.

## MATLAB API

```matlab
plan = brainnet.tools.SurfaceMergePlan(["D:/data/left.nv"; "D:/data/right.nv"]);
disp(plan.Report)
report = plan.write("D:/results/both.nv", ...
    CoordinateSpace="subject-01 native scanner frame", Units="mm", ...
    Note="Both surfaces exported from the same verified reconstruction");
```

All three metadata arguments may be omitted; `plan.write("D:/results/both.nv")` is sufficient. Use declarations only if true of your inputs. No file is overwritten. `report.output_sha256` identifies the completed file and is not embedded recursively in itself. Inspection/atlas configurations are not inherited.
