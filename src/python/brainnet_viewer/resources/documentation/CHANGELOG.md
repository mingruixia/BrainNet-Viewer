# Changes in BrainNet Viewer

## Unreleased

- Separate standalone Web graphics bootstrap from library calls; embedded/test calls no longer replace the calling process.
- Preserve optional WSL adapter selection, recognize software renderers consistently, and extend startup readiness to 90 seconds.
- Add live HTTP/WebSocket authentication and GIfTI preflight regression checks, affine-reader fixtures and a focused MATLAB reader CI job.
- Check MATLAB/Python version agreement during wheel verification; centralize Python package version metadata.
- Document the trusted-local-user security model and configurable Compose resource limits.

- Align Web Scene File / Open and Save Scene / Import Settings with the desktop editions.
- Sharpen Web still frames using 2x sampling without enlarging labels or compounding
  sampling on Apply. Reduce streamed resolution and JPEG quality during interaction.
- Temporarily reduce surface detail for CPU interaction, restoring original geometry
  for still frames, Inspect, Scene operations and export; GPU rendering retains full geometry.
- Prefer a GPU verified by an isolated graphics probe; use CPU at startup when GPU
  rendering is unavailable. Add explicit Auto/GPU/CPU selection to the local launcher.
- Update pypdf to 6.19.0 and use defusedxml for XML entity protection.
- Preserve `#` within node labels in MATLAB and Python.
- Harden Python Scene paths, duplicate-key/nonfinite checks and bounded JSON input;
  stage and verify portable assets before committing a new Scene without overwriting files.
- Restrict local Web Host/Origin and bootstrap authentication through a same-origin
  request using a random per-start key. Keep the local single-user deployment scope.
- Build source Docker images on a pinned Python 3.12 base, check dependencies and
  report HTTP health. ARM64 source rendering remains unverified; released images are unchanged.
- Clarify GPL-3.0-or-later for project code while retaining bundled-resource terms.

## 2.0.0-beta.1

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

Project code is GPL-3.0-or-later. Bundled resources retain their source credits and notices.
See the installation guides for deployment requirements and edition differences.
