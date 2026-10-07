# Command-line rendering of a saved Scene

Replay your own same-edition Scene without opening the desktop App, with explicit output dimensions and protected output files. This exercise uses the real PCC statistical map from [lesson 06](06_Statistical_Volume_to_Surface.md). It does not distribute a prebuilt Scene or run a new statistical analysis.

## Prepare the Scene in the desktop

1. Complete lesson 06 using the documented mesh and `OneSample_ROI11_NC.nii`. Use four views, mapping algorithm 2 and P = 0.05 as the shared starting configuration; retain your intended signed display and colorbar.
2. Apply the settings, render and review the figure. Save a Scene following [lesson 03](03_Scenes_and_Presets.md), for example as `pcc.scene.json` in your own project directory.
3. Retain all referenced files and companion assets. Create a separate `figures` output directory. Replace the example paths below with your actual paths; these are placeholders, not supplied files.

| Edition | Where relative inputs are resolved |
| --- | --- |
| MATLAB Desktop | The configured data root, not automatically the Scene directory. The CLI defaults to the installed BrainNetViewer folder; explicitly pass the root matching the saved references. |
| Python Desktop | The Scene directory by default. Keep its companion assets together; `--data-root` explicitly overrides that root. |

Use a Scene saved by the edition you are running. A shared JSON extension does not guarantee interchange. A preset alone does not include the inputs or complete saved session.

## MATLAB Desktop

Run in a MATLAB session with the installed BrainNetViewer folder on the MATLAB path. A MATLAB license and working graphics environment are required. Set `dataRoot` to the actual root matching your Scene references, not simply to the JSON folder.

```matlab
scenePath = "D:/my-bnv-project/pcc.scene.json";
dataRoot = "D:/my-bnv-project/data";
outputDir = "D:/my-bnv-project/figures";
if ~isfolder(outputDir), mkdir(outputDir); end

pngPath = fullfile(outputDir, "pcc-four-view-matlab.png");
record = BrainNetRender(scenePath, pngPath, ...
    DataRoot=dataRoot, ComputeBackend="cpu", ...
    PerformanceMode="quality", Width=800, Height=600, ...
    Units="pixels", Resolution=200, Overwrite=false);
info = imfinfo(pngPath);
disp([info.Width info.Height]); % Expected dimensions: 800 600
```

For a Scene whose references begin with `Data/...` in the installed library, the appropriate root is that installed BrainNetViewer folder. Desktop staging of external files requires confirmation; this CLI call does not silently stage them. `ComputeBackend="cpu"` makes the requested processing backend explicit, not a claim that graphics drivers are unused. `BrainNetRender` is not a drop-in replacement for the old `BrainNet_MapCfg` signature.

## Python Desktop

Activate the independently installed environment from [lesson 01](01_Installation_and_First_Launch.md). Run its installed `brainnet-render` entry point, not a source-tree import. No desktop window opens, but working off-screen VTK graphics support is required.

```powershell
brainnet-render --scene "D:/my-bnv-project/pcc.scene.json" --data-root "D:/my-bnv-project" --output "D:/my-bnv-project/figures/pcc-four-view-python.png" --width 800 --height 600 --units Pixels --dpi 200 --opaque
```

On macOS, substitute your actual POSIX paths for all three paths; the options are unchanged. The example root assumes the Scene and its companion asset directory are together in `my-bnv-project`. Create the output parent directory beforehand.

Success prints a JSON result containing output information, warnings and camera restoration status. A handled rendering failure reports `BrainNet render failed: ...` and exits with status 1. There is no `ComputeBackend` option in this Python CLI.

## Units, protection and another output

Both examples explicitly request an opaque PNG, 800 × 600 pixels at 200 DPI. Python uses the capitalized unit `Pixels`; MATLAB uses `pixels` here. Always state units when providing dimensions: Python can otherwise retain physical units saved in the Scene. MATLAB explicit dimensions without units default to pixels, but the explicit form is clearer.

For a separate TIFF exercise, choose a new `.tif` output filename and request 1200 × 900 pixels at 300 DPI. For transparent PNG, replace Python `--opaque` with `--transparent`; do not combine them. For physical dimensions and format limitations, see [lesson 08](08_Layouts_and_Figure_Export.md).

Existing images and their provenance records are protected. Use a new output name on the next run. Only deliberately authorize replacement with MATLAB `Overwrite=true` or Python `--overwrite`; first retain anything you need from both the image and its record. Never use the Scene JSON itself as an output path.

## Review the result

Open the image and confirm all four brains, the intended colors and colorbar are complete. Check dimensions, DPI, software identity, input hashes, settings and the accompanying provenance JSON. Review warnings rather than treating file creation alone as success. Inspect record fields for local paths, titles or sensitive labels before sharing.

Saved camera restoration depends on compatible content signatures and may fall back to the layout default. Python `--reset-view` intentionally ignores the saved camera while retaining Scene settings. Do not require pixel-identical results across graphics environments or editions.

![Historical MATLAB CLI four-view PCC illustration](../../assets/captures/tutorial08-cli/08-pcc-four-view-cli.png)

Existing MATLAB Desktop CLI illustration: 960 × 720 pixels at 150 DPI, smoothed ICBM152 mesh, P = 0.001 and mapping algorithm 5. It illustrates a complete output, not the parameters of the new commands, a Python output or acceptance of the current candidate package.

If inputs cannot be found, check the root and preserved relative structure. If a hash mismatch is reported, identify the changed input rather than editing recorded hashes to bypass validation. For output conflicts, select a new filename; for missing output directories, create the intended parent. A graphics-context failure requires a working graphics environment, not different scientific data.

These commands replay explicitly supplied Scenes. They do not discover subjects, preprocess fMRI, build connectivity matrices or provide a distributed scheduler. No desktop-free server or Docker deployment is established by this exercise.

Next: [surface and atlas tools](11_Surface_and_Atlas_Tools.md).
