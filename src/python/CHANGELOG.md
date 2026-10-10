# Changes in BrainNet Viewer

## 2.0.0-beta.1

### Compatibility

- On macOS, the canvas toolbar wraps at narrow widths so button labels remain readable.

- Native Apple Silicon macOS uses SciPy 1.17.1 to avoid the PROPACK native-library
  load failure seen with SciPy 1.15.3 on recent macOS. Python 3.11 or newer is required
  on this platform; Python 3.11 is the verified configuration.

### Editions and workspace

- MATLAB Desktop with an App-style workspace and no SPM dependency.
- Independent Python Desktop using Qt and VTK.
- Docker-hosted Web edition on port 1031, with background startup and browser access.
- Shared Data Sources, collapsible Visualization Settings, direct Apply rendering,
  Light/Dark themes, scene summaries, mesh tools and contextual Help.

### Scientific visualization

- Surface, node, edge, vertex-map, volume and atlas-ROI displays with compact multi-view layouts.
- Independent rotation, pan and zoom for each view; camera Reset and Fit.
- Fractional node and edge size scales; default edge scale 0.7.
- Current sparsity selection, directed-arrow proportions, module colors and adjustable labels.
- Common scientific colormaps including viridis, plasma, inferno, magma and cividis.
- Zero/null surface-map values retain the base surface color.
- Statistical P-value thresholds from supported NIfTI metadata, cluster-size filtering,
  signed mapping, ROI selection ranges and smoothed ROI geometry.
- AAL and Brodmann Inspect labels for appropriately aligned MNI-space inputs.

### Files and output

- Independent input readers, portable Scenes, visualization presets and custom colors.
- Merge, Convert, Subdivide and Atlas Nodes tools; camera animation.
- Figure export with pixel or physical dimensions, DPI, transparency and provenance.
- Web image and sidecar downloads remain separate; portable Scenes download as ZIP.
- Improved window sizing, dialog focus, multi-view fitting and export-state restoration.

### Resources and documentation

- All 12 supplied surface templates are retained.
- AtlasNetworks retains AAL90 and includes fourteen matched GroupFC networks,
  including AAL116, Schaefer1000 and Brainnetome246. Brodmann82, Dos160,
  Fair34 and HOA112 now have GroupFC pairs with module colors and strength sizes.
- AAL90 volume/vertex-map support files are in the atlas library; node and edge
  tutorials use AAL90. AAL3v2 and Shen278 volume filenames match their library names.
- Unified illustrated English Word/PDF manual and shared tutorials; bilingual Python
  and Docker installation instructions.

Project code is GPL-3.0. Bundled resources retain their source credits and notices.
See the installation guides for deployment requirements and edition differences.
