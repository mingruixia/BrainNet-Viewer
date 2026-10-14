# Changes in BrainNet Viewer

## Unreleased

### Web display and startup

- Align the Scene File / Open and Save Scene / Import Settings controls with the desktop editions.
- Use 2x sampling for sharper still images, while retaining label sizes and preventing
  repeated sampling on Apply. Lower stream resolution and JPEG quality during interaction.
- Reduce surface detail temporarily during CPU interaction. Restore the original geometry
  for still images, Inspect, Scene operations and export. GPU rendering keeps the full geometry.
- Test GPU rendering in a separate process at startup and use the CPU if it is unavailable.
  The local launcher also offers explicit Auto, GPU and CPU choices.
- Separate standalone Web startup from library calls so embedded use does not replace
  the calling process. Allow 90 seconds for graphics probing and service initialization.
- Retain optional WSL adapter selection and use consistent software-renderer detection.

### Input handling and security

- Update pypdf to 6.19.0 and use defusedxml for XML entity protection.
- Preserve `#` within node labels in MATLAB and Python.
- Validate Python Scene paths, bound JSON reads and reject duplicate keys or nonfinite values.
  Check portable assets before saving a new Scene without replacing existing files.
- Check local Web Host/Origin headers and obtain a random startup key through a
  same-origin request. The server remains intended for one trusted local user.
- Build source Docker images on a pinned Python 3.12 base, check dependencies and
  report HTTP health. ARM64 source rendering remains unverified; released images are unchanged.
- Clarify GPL-3.0-or-later for project code while retaining bundled-resource terms.

### Documentation and development

- Revise the English and Chinese guides, tutorials and illustrated manual for clearer instructions.
- Explain the trusted-local-user security model and configurable Compose resource limits.
- Add HTTP/WebSocket authentication, GIfTI preflight and affine-reader regression tests,
  with a MATLAB reader job in continuous integration.
- Use one source for Python version metadata and check its agreement with MATLAB during wheel verification.

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
