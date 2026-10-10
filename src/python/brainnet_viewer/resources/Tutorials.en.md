# BrainNet Viewer — Real-data Tutorials

All paths below are relative to the installed resource library. Use Add Surface,
Add Volume or Add Surface Map to select the specified files. Set options in
Visualization Settings and press Apply to render. Rotate, pan and zoom operate
on the selected view. Export Figure saves the displayed scene.

## 1. AAL vertex labels and Inspect

Surface: `Data/SurfTemplate/BrainMesh_ICBM152.nv`.
Surface Map: `atlases/AAL90/icbm_vertex_AAL_label.txt`.
Choose Single View, Left Lateral, Surface opacity 1 and Mapped surface colors.
Select a categorical palette such as hsv. Enable automatic boundaries if desired.
Enable Inspect and click the surface to display MNI coordinates, Brodmann Area
and AAL region; click Inspect again to clear the annotation. The vertex label
file belongs to this exact surface: do not substitute a differently tessellated
mesh. Zero or null vertices retain the original surface color. A vertex label
number is a region identifier, not a continuous effect size.

## 2. Real statistical volume to surface

Surface: `Data/SurfTemplate/BrainMesh_ICBM152.nv`.
Volume: `Data/Tutorials/OneSample_ROI11_NC.nii`.
Enable Volume display, select Surface Mapping, algorithm 2 (or 5), and
Positive & Negative values. Use the four-view lateral/medial layout, surface
opacity 1 and a diverging colormap such as bwr; retain the colorbar.
For thresholding, choose P Value and enter 0.05; statistics and degrees of
freedom are read from the volume header. This is an uncorrected voxel threshold
unless an explicitly justified correction has been performed separately.
Cluster size is a display filter, not a multiple-comparison correction.

The volume is a PCC-subregion seed-based one-sample functional connectivity
statistical map in standard MNI space, from Xia et al. (2014). It is not an
Alzheimer's disease versus control contrast. Surface interpolation or smoothing
does not change the statistical interpretation or provide additional inference.

## 3. Bilateral insula ROI

Surface: `Data/SurfTemplate/BrainMesh_ICBM152.nv`.
Volume: `atlases/AAL90/aal.nii`.
Enable Volume display and select ROI Drawing. Set Threshold Mode to None,
turn off Draw All ROIs, and enter ROI Selection `29,30` (left/right insula).
Use Single View, Superior, surface opacity 0.3, and Label Index ROI colors.
Choose the ROI palette explicitly; optional Gaussian smoothing with kernel 3
improves the display boundary without changing the source atlas labels.
ROI IDs refer to this AAL file, not AAL3v2 or other parcellations.

## 4. Group network example

Use the same original surface and the matching files
`Data/ExampleFiles/AtlasNetworks/Schaefer100Yeo7_GroupFC.node` and
`Schaefer100Yeo7_GroupFC.edge`. Choose Modular node colors and Mapped node size
to show modules and connection strength. Select Sparsity to reduce visual
clutter. Connections were generated from resting-state fMRI data from a group
of healthy adults. See the bundled atlas network notice for citations.

## Additional library files

The library contains AAL90 and fourteen matched GroupFC pairs, including AAL116, Schaefer1000 and Brainnetome246. See `Data/ExampleFiles/AtlasNetworks/README.md` for the complete list and citations. Pair files from the same atlas and never substitute a differently sized matrix.

References: Tzourio-Mazoyer et al. (2002), NeuroImage 15:273–289;
Xia et al. (2014), J Alzheimers Dis 39:527–543;
Xia, Wang and He (2013), PLoS ONE 8:e68910.
